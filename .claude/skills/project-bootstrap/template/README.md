# __PROJECT_NAME__

__PROJECT_DESCRIPTION__

## Futtatás

```bash
npm install
npm run dev      # helyi szerver
npm run deploy   # kézi deploy Cloudflare-re
npm run tail     # élő logok
```

## Felépítés

| Útvonal | Mi ez |
|---|---|
| `public/` | statikus fájlok, ezek szolgálódnak ki először |
| `src/index.js` | Worker — csak akkor fut, ha nincs egyező statikus fájl |
| `wrangler.jsonc` | Cloudflare konfiguráció |

## Automatikus deploy

Minden `main`-re érkező push újradeployol a GitHub Actions segítségével.
Ehhez egyszer be kell állítani a `CLOUDFLARE_API_TOKEN` repository secretet:

1. Cloudflare dashboard → My Profile → API Tokens → Create Token →
   "Edit Cloudflare Workers" sablon
2. GitHub → Settings → Secrets and variables → Actions → New repository secret

## Titkok

Helyben a `.dev.vars` fájlba (gitignore-olt). Élesben:

```bash
npx wrangler secret put NEV
```
