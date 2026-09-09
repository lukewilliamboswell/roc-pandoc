#!/usr/bin/env python3
"""Small helpers shared by GitHub Actions workflows."""

from __future__ import annotations

import argparse
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]


def roc_version() -> str:
	source = (ROOT / "package" / "main.roc").read_text(encoding="utf-8")
	matches = re.findall(r'\broc:\s*"([^"]+)"', source)
	if len(matches) != 1:
		raise ValueError("package/main.roc must contain exactly one Roc compiler pin")
	return matches[0]


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("command", choices=["roc-version"])
	parser.add_argument("--github-output", type=Path, required=True)
	args = parser.parse_args()

	if args.command == "roc-version":
		with args.github_output.open("a", encoding="utf-8") as output:
			output.write(f"nightly-tag={roc_version()}\n")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
