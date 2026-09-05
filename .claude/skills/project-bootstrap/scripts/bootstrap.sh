#!/usr/bin/env bash
#
# project-bootstrap — GitHub repo + Cloudflare Workers deploy
#
# Hitelesítést NEM kezel: a gh és a wrangler bejelentkezésére támaszkodik.
# Soha ne adj át neki tokent argumentumban vagy környezeti változóban.
#
# Használat:
#   bootstrap.sh --check
#   bootstrap.sh --init  <slug>
#   bootstrap.sh --ship  <slug> <private|public> [leírás]

set -euo pipefail

die() { printf '\033[31mHIBA:\033[0m %s\n' "$*" >&2; exit 1; }
ok()  { printf '\033[32m  ok\033[0m  %s\n' "$*"; }
step(){ printf '\n\033[1m==> %s\033[0m\n' "$*"; }

slugify() {
  # A magyar ékezetes betűket kézzel írjuk át: a 'tr' nem kezeli a
  # többbájtos karaktereket, ezért ékezet nélkül egyszerűen eltűnnének.
  # Literális cserék, nem karakterosztályok: C locale alatt a sed
  # bájtonként illeszt, és a [áÁ] alakú osztályok szétesnének.
  printf '%s' "$1" \
    | sed \
      -e 's/á/a/g;s/Á/A/g;s/à/a/g;s/â/a/g;s/ä/a/g' \
      -e 's/é/e/g;s/É/E/g;s/è/e/g;s/ê/e/g' \
      -e 's/í/i/g;s/Í/I/g;s/î/i/g' \
      -e 's/ó/o/g;s/Ó/O/g;s/ö/o/g;s/Ö/O/g;s/ő/o/g;s/Ő/O/g;s/ô/o/g' \
      -e 's/ú/u/g;s/Ú/U/g;s/ü/u/g;s/Ü/U/g;s/ű/u/g;s/Ű/U/g;s/û/u/g' \
      -e 's/ç/c/g;s/Ç/C/g;s/ñ/n/g;s/Ñ/N/g;s/ß/ss/g' \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-\{1,\}//' -e 's/-\{1,\}$//' \
    | cut -c1-54
}

# ---------------------------------------------------------------- check

cmd_check() {
  step "Előfeltételek"

  for c in git node; do
    command -v "$c" >/dev/null 2>&1 || die "'$c' nincs telepítve."
    ok "$c $("$c" --version | head -1)"
  done

  command -v gh >/dev/null 2>&1 \
    || die "A GitHub CLI ('gh') nincs telepítve. Lásd reference.md."
  ok "gh $(gh --version | head -1)"

  local major
  major=$(node -p 'process.versions.node.split(".")[0]')
  [ "$major" -ge 20 ] || die "Node 20+ kell, jelenleg: $(node --version)"

  gh auth status >/dev/null 2>&1 \
    || die "A 'gh' nincs bejelentkezve. Futtasd: gh auth login"
  ok "gh bejelentkezve mint $(gh api user --jq .login 2>/dev/null || echo '?')"

  npx --yes wrangler@4 whoami >/dev/null 2>&1 \
    || die "A wrangler nincs bejelentkezve. Futtasd: npx wrangler login"
  ok "wrangler bejelentkezve"

  printf '\nMinden előfeltétel rendben.\n'
}

# ----------------------------------------------------------------- init

cmd_init() {
  local slug="${1:-}"
  [ -n "$slug" ] || die "--init <slug> — a slug kötelező."
  slug=$(slugify "$slug")

  step "Git inicializálás: $slug"

  if [ -d .git ]; then
    ok "már git repo"
  else
    git init -q -b main
    ok "git init (main)"
  fi

  if git rev-parse HEAD >/dev/null 2>&1; then
    ok "már van commit — kihagyva"
    return 0
  fi

  [ -n "$(git status --porcelain)" ] || die "Nincs mit commitolni: a mappa üres."

  git add -A
  git commit -q -m "Initial commit: $slug"
  ok "első commit kész"
}

# ----------------------------------------------------------------- ship

cmd_ship() {
  local slug="${1:-}" vis="${2:-private}" desc="${3:-}"
  [ -n "$slug" ] || die "--ship <slug> <private|public> [leírás]"
  slug=$(slugify "$slug")

  case "$vis" in
    private|public) ;;
    *) die "A láthatóság csak 'private' vagy 'public' lehet, kapott: $vis" ;;
  esac

  git rev-parse HEAD >/dev/null 2>&1 || die "Nincs commit. Futtasd előbb: --init"

  local owner
  owner=$(gh api user --jq .login)

  step "GitHub repo: $owner/$slug ($vis)"

  if gh repo view "$owner/$slug" >/dev/null 2>&1; then
    die "A(z) $owner/$slug repo már létezik. Válassz másik nevet."
  fi

  gh repo create "$slug" \
    --"$vis" \
    --source=. \
    --remote=origin \
    --push \
    ${desc:+--description "$desc"}
  ok "repo létrehozva és felpusholva"

  step "Cloudflare deploy"

  local out
  out=$(npx --yes wrangler@4 deploy 2>&1) || {
    printf '%s\n' "$out" >&2
    die "A wrangler deploy elhasalt. Lásd reference.md."
  }
  printf '%s\n' "$out"

  local url
  url=$(printf '%s' "$out" | grep -oE 'https://[a-zA-Z0-9._-]+\.workers\.dev' | head -1)

  step "Kész"
  printf '  Repo:  https://github.com/%s/%s\n' "$owner" "$slug"
  if [ -n "$url" ]; then
    printf '  Élő:   %s\n' "$url"
  else
    printf '  Élő:   (az URL-t a fenti wrangler kimenetből olvasd ki)\n'
  fi
  printf '\n  Megjegyzés: a pushra induló automatikus deployhoz állítsd be a\n'
  printf '  CLOUDFLARE_API_TOKEN secretet a repo beállításaiban (reference.md).\n'
}

# ----------------------------------------------------------------- main

case "${1:---check}" in
  --check) cmd_check ;;
  --init)  shift; cmd_init "$@" ;;
  --ship)  shift; cmd_ship "$@" ;;
  *)       die "Ismeretlen kapcsoló: $1 (--check | --init | --ship)" ;;
esac
