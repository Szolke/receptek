# Telepítés

Ez a skill **user-szintre** való, nem projektszintre — így minden új
projektben elérhető lesz, beleértve azokat is, amikben még nincs is git repo.

```bash
mkdir -p ~/.claude/skills
cp -r project-bootstrap ~/.claude/skills/
chmod +x ~/.claude/skills/project-bootstrap/scripts/bootstrap.sh
```

Ellenőrzés: indíts egy Claude Code sessiont, és írd be, hogy `/project-bootstrap`.
Ha megjelenik a listában, kész.

## Használat

Az új projekt üres mappájában:

```
/project-bootstrap
```

vagy egyszerűen mondd, hogy „kezdjünk új projektet" — a `description` mező
alapján magától is beugrik.

Innentől a Claude Code végigvezet: ellenőrzi az előfeltételeket, bekéri a
projektnevet és a láthatóságot, bemásolja a vázat, megcsinálja az első
commitot, majd — miután rábólintottál — létrehozza a repót, felpusholja,
deployolja, és visszaadja az élő URL-t.

## Egyszeri előkészület

A skill nem kezel hitelesítést. Ha még nem tetted meg, egyszer futtasd le:

```bash
gh auth login
npx wrangler login
```

Mindkettő böngészőben nyílik meg, és a bejelentkezés a gépeden marad.

## Testreszabás

| Mit szeretnél | Hol állítsd |
|---|---|
| Más vázfájlok | `template/` — bármit tehetsz bele |
| Alapból publikus repo | `SKILL.md`, 2. lépés táblázata |
| Framework (Astro, Vite, React) | `template/package.json` + `wrangler.jsonc` `assets.directory` |
| Más deploy target | `scripts/bootstrap.sh`, `cmd_ship` függvény |

A `template/` mappa fájljaiban három helyőrző működik:
`__PROJECT_NAME__`, `__PROJECT_DESCRIPTION__`, `__COMPAT_DATE__`.
