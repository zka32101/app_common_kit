#!/usr/bin/env bash
# バージョン運用の検査（PR の CI で実行する）。
#
#   tools/check_version.sh [基準ブランチ]   # 既定は origin/main
#
# 次の3つを確かめる。どれも、実際にあった事故（同じバージョンの二重使用）を防ぐためのもの。
#  1. CHANGELOG.md に同じバージョンの見出し（## [X.Y.Z]）が2つ無い
#  2. CHANGELOG.md の先頭のバージョンが、pubspec.yaml の version と一致する
#  3. lib/ を変える PR は、まだ使われていない version にする
#     （version のタグが既にあるのにコードを変えると、そのコードはタグに含まれない）
#
# タグは origin から調べる。リリースのタグ付け自体は release-tag.yml が行う。
set -euo pipefail

base="${1:-origin/main}"
fail=0
err() { echo "NG: $*" >&2; fail=1; }

version=$(sed -n 's/^version:[[:space:]]*\([^[:space:]#]*\).*$/\1/p' pubspec.yaml | head -n1)
if ! printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  err "pubspec.yaml の version が X.Y.Z ではありません: '$version'"
  exit 1
fi

# 1. 見出しの重複
dups=$(grep -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | sort | uniq -d || true)
if [ -n "$dups" ]; then
  err "CHANGELOG.md に同じバージョンの見出しが複数あります: $(echo "$dups" | tr '\n' ' ')"
fi

# 2. 先頭のバージョンと pubspec の一致
top=$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | sed -E 's/^## \[(.*)\]$/\1/' || true)
if [ "$top" != "$version" ]; then
  err "CHANGELOG.md の先頭のバージョン($top)が、pubspec.yaml の version($version)と違います"
fi

# 3. コードを変えるのに、既にタグのある version のまま
if git rev-parse --verify -q "$base" >/dev/null; then
  if ! git diff --quiet "$base"...HEAD -- lib/ 2>/dev/null; then
    if git ls-remote --exit-code --tags origin "refs/tags/v$version" >/dev/null 2>&1; then
      err "lib/ を変えていますが、v$version のタグは既にあります。version を上げてください（CHANGELOG.md も）"
    fi
  fi
else
  echo "注意: 基準ブランチ '$base' が見つからないため、3 は検査しません" >&2
fi

if [ "$fail" = 0 ]; then
  echo "OK: version $version"
fi
exit "$fail"
