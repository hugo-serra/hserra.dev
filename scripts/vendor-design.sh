#!/usr/bin/env bash
# Vendor the design system into src/styles/vendor/hs-design.css.
#
#   scripts/vendor-design.sh <tag-or-commit>
#
# The committed file is the pin: Vercel builds from it and never fetches the
# design system, so the build needs neither a deploy key nor access to
# git.home. Changing version is a deliberate act: run this, review the diff,
# commit. Needs SSH access to git.home, so run it on a machine that has it.
set -euo pipefail

ref=${1:?usage: scripts/vendor-design.sh <tag-or-commit>}
repo=${DESIGN_REPO:-ssh://forgejo@git.home/hserra/design.git}
out=src/styles/vendor/hs-design.css

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git clone -q "$repo" "$tmp/design"
git -C "$tmp/design" -c advice.detachedHead=false checkout -q "$ref"
commit=$(git -C "$tmp/design" rev-parse HEAD)

# Inline every relative @import in order, recursively, which is what the
# bundler did with `@import "@hs/design"`. External imports (the web font) are
# hoisted to the top: CSS ignores an @import that follows any other rule, and
# the minifier silently drops it, so left in place the font would vanish.
local_re="^@import +[\"']\./([^\"']+)[\"'] *; *$"
external_re="^@import +url\("
inline() {
  local file=$1 dir line
  dir=$(dirname "$file")
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ $line =~ $local_re ]]; then
      inline "$dir/${BASH_REMATCH[1]}"
    elif [[ $line =~ $external_re ]]; then
      printf '%s\n' "$line" >>"$tmp/external"
    else
      printf '%s\n' "$line"
    fi
  done <"$file"
}

mkdir -p "$(dirname "$out")"
: >"$tmp/external"
inline "$tmp/design/src/index.css" >"$tmp/body"
{
  printf '/* Vendored from hserra/design %s (%s) by scripts/vendor-design.sh.\n' "$ref" "$commit"
  printf '   Do not edit by hand: re-run the script to change version. */\n\n'
  sort -u "$tmp/external"
  cat "$tmp/body"
} >"$out"
echo "wrote $out from $ref ($commit)"
