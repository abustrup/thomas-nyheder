#!/usr/bin/env bash
# Put Thomas' Nyheder on the internet.
#
# The repo abustrup/thomas-nyheder already exists and is public. What is left is
# to push this clone to it and turn on GitHub Pages.
#
# This version deliberately does NOT depend on the `gh` CLI for the push.
# The first version did, and it failed from Terminal.app with "Not logged in"
# even though gh was installed, on PATH, and authenticated — because gh keeps its
# token in the macOS Keychain under an access-control list tied to the app that
# created it, and a different app reading it is denied rather than prompted.
#
# `git push` uses a different mechanism entirely: the osxkeychain credential
# helper, which is what has been publishing the other brief every morning for
# weeks. So the push below works from any terminal, and gh is used only for the
# one thing it is needed for — enabling Pages — with a manual fallback printed if
# it is unavailable.
#
# Safe to re-run: every step is skipped if it is already done.
# To undo everything:  gh repo delete abustrup/thomas-nyheder --yes
set -euo pipefail

REPO="abustrup/thomas-nyheder"
URL="https://abustrup.github.io/thomas-nyheder/"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "==> pushing $(git rev-list --count HEAD) commits to $REPO"
if git push -u origin main; then
  echo "    pushed"
else
  echo >&2
  echo "ERROR: the push failed." >&2
  echo "If it asked for a username and password, GitHub no longer accepts those." >&2
  echo "Fix it once with:  gh auth setup-git   (or store a token in Keychain Access)" >&2
  exit 1
fi

echo "==> enabling GitHub Pages (/docs on main)"
PAGES_DONE=0
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  if gh api "repos/$REPO/pages" >/dev/null 2>&1; then
    echo "    already enabled"; PAGES_DONE=1
  elif gh api -X POST "repos/$REPO/pages" \
        -f 'source[branch]=main' -f 'source[path]=/docs' >/dev/null 2>&1; then
    echo "    enabled"; PAGES_DONE=1
  fi
fi

if [ "$PAGES_DONE" -eq 0 ]; then
  cat <<EOF

The push worked. Only Pages is left, and this terminal cannot reach the GitHub
API — do it in the browser instead, it takes three clicks:

  1. open  https://github.com/$REPO/settings/pages
  2. under "Build and deployment", set Source = "Deploy from a branch"
  3. set Branch = "main" and folder = "/docs", then press Save

Then wait a minute or two and open:  $URL

EOF
  exit 0
fi

echo "==> waiting for $URL to answer (GitHub takes a minute on the first build)"
for _ in $(seq 1 40); do
  code="$(curl -s -o /dev/null -w '%{http_code}' "$URL" || true)"
  if [ "$code" = "200" ]; then
    echo
    echo "LIVE: $URL"
    exit 0
  fi
  sleep 15
done

echo
echo "Pushed and Pages is enabled, but the site has not answered yet."
echo "That is normal on a first build. Check in a few minutes: $URL"
