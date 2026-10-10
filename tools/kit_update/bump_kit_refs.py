#!/usr/bin/env python3
"""pubspec.yaml の git 依存（タグ固定）を、最新のリリースタグへ上げる。

  python3 bump_kit_refs.py [pubspec.yaml] [--owner zka32101] [--summary summary.md]

- 対象: `url` が github.com/<owner>/ 配下で、`ref` が vX.Y.Z の形の git 依存（app_common_kit・ukalab_core・cross_promo_kit など）
- 上げるのは、今の ref より新しい vX.Y.Z タグだけ（下げない・プレリリースは無視）
- 変えたら、変更内容を --summary のファイルに Markdown で書き、`GITHUB_OUTPUT` があれば changed=true/false を出す
- major が上がるときは、要注意として印を付ける（破壊的変更の可能性）

各アプリの GitHub Actions（templates/kit-update.yml）から呼ぶ。
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys

TAG_RE = re.compile(r"^v(\d+)\.(\d+)\.(\d+)$")

# 例:
#   app_common_kit:
#     git:
#       url: https://github.com/zka32101/app_common_kit.git
#       ref: v0.24.0
BLOCK_RE = re.compile(
    r"(?P<head>^[ \t]+(?P<name>[A-Za-z0-9_]+):[ \t]*\n[ \t]+git:[ \t]*\n[ \t]+url:[ \t]*(?P<url>\S+)[ \t]*\n[ \t]+ref:[ \t]*)(?P<ref>v\d+\.\d+\.\d+)",
    re.M,
)


def parse_tag(tag: str):
    m = TAG_RE.match(tag)
    return tuple(int(x) for x in m.groups()) if m else None


def list_tags(url: str) -> list[str]:
    """リモートのタグ名（vX.Y.Z の形のものだけ）を返す。"""
    out = subprocess.run(
        ["git", "ls-remote", "--tags", "--refs", url],
        check=True, capture_output=True, text=True,
    ).stdout
    tags = [line.split("refs/tags/", 1)[1] for line in out.splitlines() if "refs/tags/" in line]
    return [t for t in tags if parse_tag(t)]


def latest(tags: list[str]) -> str | None:
    good = [t for t in tags if parse_tag(t)]
    return max(good, key=parse_tag) if good else None


def bump(text: str, owner: str, tag_lister=list_tags):
    """(新しい本文, 変更の一覧) を返す。変更 = (name, 旧ref, 新ref, majorが上がるか)"""
    changes: list[tuple[str, str, str, bool]] = []

    def repl(m: re.Match) -> str:
        url = m.group("url")
        if f"github.com/{owner}/" not in url:
            return m.group(0)
        new = latest(tag_lister(url))
        cur = m.group("ref")
        if new and parse_tag(new) > parse_tag(cur):
            changes.append((m.group("name"), cur, new, parse_tag(new)[0] > parse_tag(cur)[0]))
            return m.group("head") + new
        return m.group(0)

    return BLOCK_RE.sub(repl, text), changes


def summary(changes) -> str:
    lines = ["共通基盤のタグを更新します。", "", "| パッケージ | 旧 | 新 | |", "|---|---|---|---|"]
    for name, old, new, major in changes:
        lines.append(f"| `{name}` | {old} | {new} | {'⚠ major（破壊的変更の可能性。CHANGELOG の移行手順を確認）' if major else ''} |")
    lines += ["", "CI（analyze・test）が通ることを確認してからマージしてください。失敗したら、各パッケージの CHANGELOG.md の移行手順を見てください。"]
    return "\n".join(lines) + "\n"


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("pubspec", nargs="?", default="pubspec.yaml")
    ap.add_argument("--owner", default="zka32101")
    ap.add_argument("--summary", default=None)
    a = ap.parse_args(argv)

    text = open(a.pubspec, encoding="utf-8").read()
    new_text, changes = bump(text, a.owner)
    if changes:
        open(a.pubspec, "w", encoding="utf-8").write(new_text)
        for name, old, new, major in changes:
            print(f"{name}: {old} -> {new}{'  (major)' if major else ''}")
        if a.summary:
            open(a.summary, "w", encoding="utf-8").write(summary(changes))
    else:
        print("更新はありません。")
    gh = os.environ.get("GITHUB_OUTPUT")
    if gh:
        with open(gh, "a", encoding="utf-8") as f:
            f.write(f"changed={'true' if changes else 'false'}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
