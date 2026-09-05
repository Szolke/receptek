---
name: project-bootstrap
description: Új projekt indítása nulláról — GitHub repo létrehozása, Cloudflare Workers deploy, és az élő URL visszaadása. Akkor használd, amikor a felhasználó új projektet kezd és még nincs git repo (vagy van, de nincs remote és nincs commit). Trigger kifejezések - "új projekt", "bootstrap", "hozzuk létre a repót", "tegyük ki Cloudflare-re", "deploy", "induljunk". Ne használd meglévő, már deployolt projekt módosításához.
allowed-tools: Read, Write, Edit, Glob, Bash
user-invocable: true
---

# Projekt bootstrap: GitHub + Cloudflare

Új projektet indítunk. A cél: működő repo a GitHubon, élő deploy a Cloudflare-en,
és a végén egy URL, ami megnyitható.

## Alapelvek

- **Soha ne kérj be tokent, jelszót vagy API kulcsot.** A `gh` és a `wrangler`
  már be van jelentkezve a felhasználó gépén. Ha nincs, állítsd meg a folyamatot
  és mondd meg, melyik parancsot futtassa (lásd `reference.md`).
- **A repo létrehozása és a deploy nem visszavonható.** Mindkettő előtt kérj
  megerősítést a 2. lépésben egyeztetett paraméterekkel.
- **Ne találj ki nevet.** Ha a felhasználó nem mondott projektnevet, kérdezd meg.

## Folyamat

### 1. Előfeltételek ellenőrzése

```bash
scripts/bootstrap.sh --check
```

Ez megnézi, hogy megvan-e a `git`, `gh`, `node`, és hogy be van-e jelentkezve
a `gh` és a `wrangler`. Ha bármelyik hiányzik, állj meg és `reference.md`
alapján mondd meg, mit tegyen a felhasználó. Ne próbáld megkerülni.

### 2. Paraméterek egyeztetése

Kérdezd meg — egyszerre, egy üzenetben:

| Paraméter | Alapértelmezés |
|---|---|
| Projektnév (repo + Worker neve) | az aktuális mappa neve |
| Láthatóság | `private` |
| Egysoros leírás | üres |

A projektnév legyen kisbetűs, kötőjeles slug. Ha a megadott név nem az,
alakítsd át és mutasd meg, mire alakítottad.

### 3. Vázfájlok bemásolása

Ha a mappa üres vagy nincs benne `package.json`, másold be a `template/`
tartalmát az aktuális mappába, majd cseréld ki a helyőrzőket:

- `__PROJECT_NAME__` → a slug
- `__PROJECT_DESCRIPTION__` → a leírás
- `__COMPAT_DATE__` → a mai dátum `YYYY-MM-DD` formában

Ha a mappában **már van** kód, ne írj felül semmit. Csak azokat a fájlokat
told be, amik hiányoznak (`wrangler.jsonc`, `.gitignore`, workflow), és
szólj a felhasználónak, mit hagytál békén.

### 4. Első commit

```bash
scripts/bootstrap.sh --init "<slug>"
```

Ez elvégzi a `git init`-et (ha kell), a `git add -A`-t és az első commitot.
Deployt még nem csinál.

### 5. Megerősítés kérése

Mielőtt továbbmész, foglald össze egy üzenetben:

> Létrehozom a `<owner>/<slug>` repót (`private`), felpusholom, és deployolom
> Cloudflare-re `<slug>` néven. Mehet?

Várd meg a választ. Ne folytasd hallgatólagos beleegyezéssel.

### 6. Repo + deploy

```bash
scripts/bootstrap.sh --ship "<slug>" "<private|public>" "<leírás>"
```

Ez sorrendben: `gh repo create` → push → `wrangler deploy`.

### 7. Eredmény

Add vissza mindkét URL-t külön sorban:

- Repo: `https://github.com/<owner>/<slug>`
- Élő: a `wrangler deploy` kimenetéből kiolvasott `*.workers.dev` cím

A `wrangler` kimenetéből olvasd ki a tényleges URL-t — **ne** rakd össze
sablonból, mert a Workers subdomain fiókonként eltér.

Végül említsd meg egy mondatban, hogy a push-ra induló automatikus deployhoz
be kell állítani a `CLOUDFLARE_API_TOKEN` secretet a repo beállításaiban —
ezt a felhasználó teszi meg saját maga, lásd `reference.md`.

## Hibakezelés

Ha bármelyik lépés elhasal, **ne ugorj tovább** a következőre. A részleteket
és a tipikus hibaüzeneteket lásd: `reference.md`.
