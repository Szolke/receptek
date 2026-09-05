# Referencia

Háttéranyag a `project-bootstrap` skillhez. A SKILL.md a folyamat, ez a tudásbázis.

---

## Előfeltételek

| Eszköz | Ellenőrzés | Ha hiányzik |
|---|---|---|
| git | `git --version` | rendszerspecifikus telepítés |
| GitHub CLI | `gh --version` | `brew install gh` / `winget install GitHub.cli` / `apt install gh` |
| Node.js 20+ | `node --version` | nodejs.org vagy nvm |
| gh bejelentkezés | `gh auth status` | `gh auth login` — böngészős folyamat |
| wrangler bejelentkezés | `npx wrangler whoami` | `npx wrangler login` — böngészős OAuth |

**Fontos:** mindkét bejelentkezés interaktív, böngészőn keresztül történik.
Az agent ne próbáljon tokent bekérni vagy környezeti változóba írni — a
felhasználó futtatja a `login` parancsot, és onnantól a hitelesítés a gépén
tárolódik.

---

## Cloudflare: miért Workers és nem Pages

2026-ban a Cloudflare új projektekhez a **Workers static assets** megoldást
ajánlja Pages helyett, mert egy deploymentben egyesíti a frontendet és a
backendet. A Pages továbbra is támogatott, meglévő projektet nem kell
sürgősen átköltöztetni.

A `wrangler.jsonc` a modern konfigurációs formátum. A `main` kulcs
opcionális, ha csak statikus fájlokat szolgálsz ki. Ha `main` is meg van
adva, alapból a statikus asset nyer, és a Worker csak akkor fut le, ha nincs
egyező fájl — ezért működik az `/api/*` útvonal a sablonban külön routing nélkül.

A **Workers Sites** (`site` kulcs) elavult, ne használd új projekthez.

Dokumentáció: https://developers.cloudflare.com/workers/static-assets/

---

## Tipikus hibák

### `gh repo create` — name already exists

A név foglalt a fiókban. Kérdezz új nevet, ne írj felül semmit és ne
generálj automatikusan `-2` utótagot.

### `wrangler deploy` — "You need to register a workers.dev subdomain"

A fiókhoz még nincs workers.dev subdomain. A felhasználónak egyszer be kell
állítania a Cloudflare dashboardon (Workers & Pages → Subdomain). Utána a
deploy újrafuttatható.

### `wrangler deploy` — Authentication error

Lejárt az OAuth session. `npx wrangler logout && npx wrangler login`.

### A push elhasal `src refspec main does not match any` hibával

Nincs még commit. Vissza a 4. lépésre.

---

## Automatikus deploy pushra

A sablonban lévő `.github/workflows/deploy.yml` minden `main`-re érkező
pushnál újradeployol. Ehhez egyetlen repository secret kell:
`CLOUDFLARE_API_TOKEN`.

Ezt **a felhasználó állítja be saját maga**, két lépésben:

1. Cloudflare dashboard → My Profile → API Tokens → Create Token →
   "Edit Cloudflare Workers" sablon.
2. GitHub repo → Settings → Secrets and variables → Actions → New
   repository secret, néven `CLOUDFLARE_API_TOKEN`.

Az agent ne kérje be a token értékét, ne írja fájlba, és ne futtasson
`gh secret set` parancsot a token szövegével.

Amíg a secret nincs beállítva, a workflow elhasal — ez várható, és nem
befolyásolja a `bootstrap.sh --ship` által elvégzett első deployt.

---

## A sablon felépítése

```
public/index.html          statikus belépő
src/index.js               Worker — /api/health, egyébként asset
wrangler.jsonc             Cloudflare konfiguráció
package.json               dev + deploy scriptek, wrangler devDependency
.gitignore                 node_modules, .wrangler, .dev.vars, .env
.github/workflows/deploy.yml
README.md
```

A `.dev.vars` szándékosan gitignore-olt: ide kerülnek a helyi titkok.
Éles környezetbe `npx wrangler secret put NEV` paranccsal kerülnek —
szintén a felhasználó futtatja, interaktívan.
