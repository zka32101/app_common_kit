#!/usr/bin/env bash
# pubspec.yaml の version から、リリースタグ vX.Y.Z を付ける。
#
#   tools/release_tag.sh [--dry-run] [コミット]   # コミットの既定は HEAD
#
# - すでに同じタグがあれば何もしない（タグは不変。付け替えない）。
# - version が X.Y.Z の形でなければ失敗する（ビルド番号 +N 付きも失敗）。
# - 付けたタグは origin に push する（--dry-run のときは何もせず表示だけ）。
set -euo pipefail

dry=0
if [ "${1:-}" = "--dry-run" ]; then dry=1; shift; fi
commit="${1:-HEAD}"

version=$(git show "$commit:pubspec.yaml" | sed -n 's/^version:[[:space:]]*\([^[:space:]#]*\).*$/\1/p' | head -n1)
if ! printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "pubspec.yaml の version が X.Y.Z ではありません: '$version'" >&2
  exit 1
fi
tag="v$version"
sha=$(git rev-parse "$commit^{commit}")

if git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1; then
  echo "$tag は既にあります。何もしません。"
  exit 0
fi

echo "$tag を ${sha:0:7} に付けます。"
if [ "$dry" = 1 ]; then exit 0; fi
git tag -a "$tag" "$sha" -m "$tag"
git push origin "refs/tags/$tag"
