#!/usr/bin/env python3
"""Create the distributable Roc package bundle."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--output-dir", type=Path, default=ROOT / "dist")
	args, roc_args = parser.parse_known_args()
	output_dir = args.output_dir.resolve()
	output_dir.mkdir(parents=True, exist_ok=True)

	package_dir = ROOT / "package"
	roc_files = [package_dir / "main.roc"]
	roc_files.extend(sorted(path for path in package_dir.glob("*.roc") if path.name != "main.roc"))
	command = [
		os.environ.get("ROC", "roc"),
		"bundle",
		*(path.name for path in roc_files),
		"--output-dir",
		str(output_dir),
		*roc_args,
	]
	return subprocess.run(command, cwd=package_dir, check=False).returncode


if __name__ == "__main__":
	raise SystemExit(main())
