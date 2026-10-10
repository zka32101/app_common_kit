import unittest

import bump_kit_refs as b

PUBSPEC = """\
dependencies:
  flutter:
    sdk: flutter
  app_common_kit:
    git:
      url: https://github.com/zka32101/app_common_kit.git
      ref: v0.24.0
  ukalab_core:
    git:
      url: https://github.com/zka32101/ukalab_core.git
      ref: v0.22.0
  other_pkg:
    git:
      url: https://github.com/someone/other.git
      ref: v1.0.0
  cross_promo_kit:
    git:
      url: https://github.com/zka32101/cross_promo_kit
      ref: v0.2.0
  path_pkg:
    path: ../x
"""

TAGS = {
    "app_common_kit": ["v0.9.0", "v0.24.0", "v0.30.0", "v1.0.0", "v1.0.0-rc1", "vfoo", "v0.25.1"],
    "ukalab_core": ["v0.22.0", "v0.23.0", "v0.24.0"],
    "cross_promo_kit": ["v0.2.0"],
    "other": ["v9.9.9"],
}


def lister(url):
    name = url.rstrip("/").split("/")[-1].removesuffix(".git")
    return TAGS[name]


class BumpTest(unittest.TestCase):
    def test_latest_ignores_non_release_tags(self):
        self.assertEqual(b.latest(TAGS["app_common_kit"]), "v1.0.0")
        self.assertIsNone(b.latest(["vfoo", "v1.0.0-rc1"]))

    def test_numeric_order_not_string_order(self):
        self.assertEqual(b.latest(["v0.9.0", "v0.10.0", "v0.2.0"]), "v0.10.0")

    def test_bumps_only_owner_deps_and_newer_tags(self):
        text, changes = b.bump(PUBSPEC, "zka32101", lister)
        self.assertIn("ref: v1.0.0\n  ukalab_core", text)
        self.assertIn("url: https://github.com/zka32101/ukalab_core.git\n      ref: v0.24.0", text)
        # 他人のリポジトリは触らない
        self.assertIn("url: https://github.com/someone/other.git\n      ref: v1.0.0", text)
        # すでに最新
        self.assertIn("cross_promo_kit\n      ref: v0.2.0", text)
        self.assertEqual(
            [(n, o, w, m) for n, o, w, m in changes],
            [("app_common_kit", "v0.24.0", "v1.0.0", True), ("ukalab_core", "v0.22.0", "v0.24.0", False)],
        )

    def test_never_downgrades(self):
        text = PUBSPEC.replace("ref: v0.24.0", "ref: v2.0.0", 1)
        out, changes = b.bump(text, "zka32101", lister)
        self.assertIn("ref: v2.0.0", out)
        self.assertEqual([c[0] for c in changes], ["ukalab_core"])

    def test_no_change_when_up_to_date(self):
        text = PUBSPEC.replace("v0.24.0", "v1.0.0", 1).replace("v0.22.0", "v0.24.0")
        out, changes = b.bump(text, "zka32101", lister)
        self.assertEqual(out, text)
        self.assertEqual(changes, [])

    def test_summary_marks_major(self):
        s = b.summary([("app_common_kit", "v0.24.0", "v1.0.0", True), ("ukalab_core", "v0.22.0", "v0.24.0", False)])
        self.assertIn("major", s)
        self.assertEqual(s.count("major"), 1)


if __name__ == "__main__":
    unittest.main()
