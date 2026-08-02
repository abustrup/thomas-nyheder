#!/usr/bin/env bash
# Put Thomas' Nyheder on the internet.
#
# Everything else is already built and verified. This is the one step that was
# deliberately left for you, because it publishes a new public website under your
# GitHub account, and that is your call rather than Claude's.
#
# What it does, in order:
#   1. creates the PUBLIC repo abustrup/thomas-nyheder
#   2. pushes this clone to it (README, .nojekyll, and any editions published so far)
#   3. turns on GitHub Pages, serving /docs on main
#   4. prints the live URL and waits for it to answer
#
# Safe to re-run: every step is skipped if it is already done.
#
# To undo the whole thing:  gh repo delete abustrup/thomas-nyheder --yes
set -euo pipefail

REPO="abustrup/thomas-nyheder"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "==> checking GitHub login"
gh auth status >/dev/null 2>&1 || { echo "Not logged in. Run: gh auth login" >&2; exit 1; }

echo "==> creating $REPO (public)"
if gh repo view "$REPO" >/dev/null 2>&1; then
  echo "    already exists — skipping"
else
  gh repo create "$REPO" --public \
    --description "Thomas' Nyheder — dagligt dansk morgenbrief" >/dev/null
  echo "    created"
fi

echo "==> pushing"
git push -u origin main

echo "==> enabling GitHub Pages (/docs on main)"
if gh api "repos/$REPO/pages" >/dev/null 2>&1; then
  echo "    already enabled — skipping"
else
  gh api -X POST "repos/$REPO/pages" \
    -f 'source[branch]=main' -f 'source[path]=/docs' >/dev/null
  echo "    enabled"
fi

URL="https://abustrup.github.io/thomas-nyheder/"
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
