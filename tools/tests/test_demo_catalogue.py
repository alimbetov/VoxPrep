"""Deterministic DEV/TEST catalogue contract tests (no external services)."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from generate_demo_catalogue import BASE, build, flutter_source


class DemoCatalogueGeneratorTest(unittest.TestCase):
    def test_deterministic_same_seed(self):
        self.assertEqual(build(2026, 32), build(2026, 32))
        self.assertEqual(flutter_source(build(2026, 32)),
                         flutter_source(build(2026, 32)))

    def test_unique_ids_and_per_category_free_first_block(self):
        records = build(2026, 64)["items"]
        self.assertEqual(64, len(records))
        self.assertEqual(64, len({x["code"] for x in records}))
        seen = set()
        for item in records:
            self.assertEqual("FULL" if item["category"] in seen else "FREE",
                             item["accessLevel"])
            seen.add(item["category"])

    def test_preset_legacy_codes_are_stable(self):
        items = build(2026, 32)["items"]
        self.assertEqual([x[0] for x in BASE],
                         [x["code"] for x in items[:len(BASE)]])
        self.assertTrue(all(x["type"] in
                            {"interview", "topic", "vocabulary", "shadowing", "phrase"}
                            for x in items))

    def test_bounds_and_seed(self):
        with self.assertRaises(ValueError):
            build(2026, 6)
        with self.assertRaises(ValueError):
            build(2026, 201)
        self.assertNotEqual(build(2026, 32)["items"][7]["level"],
                            build(2027, 32)["items"][7]["level"])


if __name__ == "__main__":
    unittest.main()
