---
name: kozzetetel
description: A Receptesdoboz élesítése – ellenőrzés, commit, push a GitHub main ágra, majd wrangler deploy a Cloudflare Workersre (nem Pages) és a deploy visszaigazolása. Használd MINDIG, ha Szolke azt mondja hogy "pusholj", "deploy", "élesítsd", "menjen ki", "töltsd fel", "commitold", "mehet élesbe", vagy bármi mást, ami a változtatások közzétételét jelenti – akkor is, ha csak annyit mond, hogy "kész, mehet".
---

# Közzététel: GitHub + Cloudflare Workers (static assets)

A Receptesdoboz **nem Cloudflare Pages projekt**, hanem Cloudflare Workers, statikus
asset-ekkel kiszolgálva (lásd `wrangler.jsonc`: `name: "receptek"`,
`assets.directory: ./`). Nincs is a `wrangler pages project list`
listában – ha ott keresed, nem találod, és a `wrangler pages deploy` hibával
elhasal ("The Pages project ... does not exist").

Két külön lépés, ne mosd össze őket:

1. **Push** – a `main` ágra, ez csak a verziótörténet.
2. **`wrangler deploy`** – ez megy ki élesbe, közvetlen feltöltéssel.

Vagyis a GitHubon lévő állapot és az élesben futó állapot **szétcsúszhat**. Ezért
mindig együtt csináld a kettőt, és ha valamiért csak az egyik sikerül, mondd meg
kimondottan, hogy melyik.

Projekt: `receptek` · ág: `main` · egyetlen statikus `index.html` a gyökérben
(nincs külön `public/` mappa, a `wrangler.jsonc` a repo gyökerét szolgálja ki
a `.assetsignore`-ban felsoroltak kivételével).

## 1. Mi változott

```bash
git branch --show-current
git status --porcelain
git diff --stat
```

Ha nem `main` ágon vagy, állj meg és kérdezd meg, hova menjen.
Ha nincs változás, mondd meg és fejezd be – ne csinálj üres commitot.

Olvasd át a tényleges diffet is (`git diff`), nem csak a fájlneveket: a commit
üzenethez is kell.

## 2. Ellenőrzőlista élesítés előtt

**Szintaktika** – ha van módosított JS/CSS beágyazva az `index.html`-ben, olvasd
át a diffet figyelmesen, mert nincs külön build/lint lépés, ami elkapná a hibát.

**Nem odavaló fájlok** – ezek soha nem mehetnek fel:
- `.env`, API token, Cloudflare kulcs, bármi hitelesítő adat
- `node_modules/`, `.wrangler/`, `.DS_Store`
- nyers, nem optimalizált képek (több MB-os PNG/JPG) – ha képet adsz hozzá,
  nézd meg a méretét és szólj, ha gyanúsan nagy
```bash
git diff --cached --name-only | xargs -I{} du -h {} 2>/dev/null | sort -rh | head
```
Bármi 300 kB fölött magyarázatot igényel – szólj róla, mielőtt bemegy.

**`.assetsignore` ellenőrzése** – ha új konfigurációs vagy belső fájlt adtál a
repo gyökeréhez (pl. új `.json`, `.lock` fájl), nézd meg, hogy nem kerül-e fel
véletlenül élesbe statikus asset-ként. A `.git`, `.github`, `.claude`,
`.wrangler`, `node_modules`, `wrangler.jsonc`, `package.json` már ki van zárva.

## 3. Commit

Magyar, egy soros, kijelentő összefoglaló – mit csinál most az oldal, nem azt,
hogy melyik fájlt piszkáltad. Ha több különálló dolog változott, csinálj több
commitot.

**Példák**
Változás: új recept hozzáadva a listához
→ `Túrós rétes recept hozzáadva`

Változás: a keresőmező most ékezet nélkül is talál egyezést
→ `Ékezet-független keresés a receptek között`

Kerüld: `fix`, `update`, `wip`, `apró javítás`.

## 4. Megerősítés, majd push

A deploy után azonnal az új verzió fut élesben, ezért **mindig mutasd meg
előtte** a commit üzenetet és a fájllistát, és várd meg Szolke jóváhagyását.
Egyszer kérdezz, a push + deploy párosra együtt.

```bash
git push origin main
```

Soha ne `--force`-olj a `main`-re. Ha a push elhasal (pl. eltérés a távolival),
**ne deploy-olj** – előbb tisztázd a git állapotot.

## 5. Deploy

Csak tiszta munkakönyvtárból, a push után:

```bash
npx wrangler deploy
```

- Ne használd a `wrangler pages deploy`-t és a `--project-name` / `--branch`
  Pages-kapcsolókat – ez a projekt Workers, nem Pages, a parancs azonnal
  hibával elhasal ("The Pages project ... does not exist").
- A `wrangler.jsonc`-ban lévő `name: "receptek"` határozza meg, melyik
  Workerre megy a deploy – külön projektnevet nem kell megadni.
- Ha a wrangler `--commit-dirty` figyelmeztetést ad, az azt jelenti, hogy maradt
  nem commitolt változás. Ne kapcsold ki a figyelmeztetést – menj vissza a 3.
  ponthoz, mert az élesben ilyenkor olyasmi lesz, ami sehol nincs elmentve.
- Ha nincs belépve (hiányzó `CLOUDFLARE_API_TOKEN` vagy lejárt session), ne kezdj
  el tokent állítgatni vagy fájlba írni – szólj Szolkénak, hogy lépjen be.

Ehelyett azt is megteheted, hogy csak pusholsz, és hagyod, hogy a
`.github/workflows/deploy.yml` (GitHub Actions, `CLOUDFLARE_API_TOKEN` secret)
automatikusan deployoljon. Ha ezt választod, a push után ellenőrizd a workflow
futásának kimenetelét (`gh run list --workflow=deploy.yml --limit 1`), ne csak
feltételezd, hogy sikerült.

## 6. Visszaigazolás

A `wrangler deploy` (vagy a GitHub Actions futás) kimenete kiírja az uploadolt
asset-ek számát és a produkciós URL-t
(`https://receptek.szolke-53e.workers.dev`). Utána írd ki:
- a produkciós URL-t,
- egy mondatban, hogy mit érdemes most kipróbálni.

## 7. Ha valami elromlik

Közvetlen feltöltésnél (és Actions-nél is) nincs igazi build log, ezért a hibák
nem a deploy alatt jönnek elő, hanem a böngészőben. Tipikus okok, sorrendben:

1. **Kis-nagybetű eltérés** a fájlnévben – a Cloudflare kiszolgálója
   különbséget tesz, ez néma 404 lesz.
2. Hiányzó asset: az `index.html` olyan fájlra hivatkozik, ami nincs a repóban.
3. Régi verzió a képernyőn: a böngésző cache-el. Előbb kényszerített frissítés,
   és csak utána keresd a hibát.

Rollback: a Cloudflare dashboardon az előző deploymentnél *Rollback* – ez
másodpercek alatt visszaállítja az élest. Ezt csináld először, és csak utána
keresd a hibát nyugodtan. Ne kezdj el pánikból `git revert`-elni.

## Amit soha

- Ne írj titkot a repóba – a Cloudflare Workers környezeti változóiba/secretjeibe való.
- Ne deploy-olj push nélkül. Ha csak az egyik ment át, mondd ki, hogy melyik.
