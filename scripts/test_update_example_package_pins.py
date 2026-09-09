#!/usr/bin/env python3
"""Unit tests for release example dependency updates."""

from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

import update_example_package_pins as pins


class UpdateExamplePackagePinsTests(unittest.TestCase):
	def test_updates_nested_and_top_level_app_roots(self) -> None:
		with tempfile.TemporaryDirectory() as temporary:
			examples = Path(temporary)
			first = examples / "hello.roc"
			first.write_text('app [main!] { pandoc: "../package/main.roc" }\n', encoding="utf-8")
			nested = examples / "report" / "main.roc"
			nested.parent.mkdir()
			nested.write_text('app [main!] { pandoc: "../../package/main.roc" }\n', encoding="utf-8")
			module = examples / "Support.roc"
			module.write_text("Support := {}\n", encoding="utf-8")

			updated = pins.update_examples(examples, "https://example.test/package.tar.zst")

			self.assertEqual(updated, [first, nested])
			self.assertIn('pandoc: "https://example.test/package.tar.zst"', first.read_text())
			self.assertIn('pandoc: "https://example.test/package.tar.zst"', nested.read_text())
			self.assertEqual(module.read_text(), "Support := {}\n")

	def test_reads_single_bundle_manifest(self) -> None:
		with tempfile.TemporaryDirectory() as temporary:
			manifest = Path(temporary) / "bundles.json"
			manifest.write_text(json.dumps([{"artifact_file": "abc123.tar.zst"}]), encoding="utf-8")
			self.assertEqual(pins.artifact_from_manifest(manifest), "abc123.tar.zst")

	def test_rejects_multiple_bundles(self) -> None:
		with tempfile.TemporaryDirectory() as temporary:
			manifest = Path(temporary) / "bundles.json"
			manifest.write_text(json.dumps([{"artifact_file": "a.tar.zst"}, {"artifact_file": "b.tar.zst"}]), encoding="utf-8")
			with self.assertRaisesRegex(ValueError, "exactly one"):
				pins.artifact_from_manifest(manifest)


if __name__ == "__main__":
	unittest.main()
