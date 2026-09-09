#!/usr/bin/env python3
"""Run every repository check used by CI."""

from __future__ import annotations

import concurrent.futures
import os
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
ROC = os.environ.get("ROC", "roc")


def run(command: list[str]) -> int:
	print(f"\n$ {' '.join(command)}", flush=True)
	return subprocess.run(command, cwd=ROOT, check=False).returncode


def check_example(path: Path) -> tuple[Path, int]:
	completed = subprocess.run(
		[ROC, "check", str(path.relative_to(ROOT)), "--no-cache"],
		cwd=ROOT,
		check=False,
	)
	return path, completed.returncode


def main() -> int:
	if run([ROC, "fmt", "--check", "package", "examples", "tests/cases"]):
		return 1
	if run([ROC, "check", "package/main.roc", "--no-cache"]):
		return 1
	if run([sys.executable, "scripts/test.py", "--require-pandoc"]):
		return 1

	examples = sorted((ROOT / "examples").glob("*.roc"))
	with concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count() or 1) as pool:
		for path, status in pool.map(check_example, examples):
			print(f"{'PASS' if status == 0 else 'FAIL'} {path.relative_to(ROOT)}")
			if status:
				return status

	with tempfile.TemporaryDirectory(prefix="roc-pandoc-docs-") as output:
		if run([ROC, "docs", "package/main.roc", f"--output={output}", "--no-cache"]):
			return 1

	return run(["git", "diff", "--check"])


if __name__ == "__main__":
	raise SystemExit(main())
