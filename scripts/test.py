#!/usr/bin/env python3
"""Run Roc golden apps in parallel and compare or regenerate their JSON output."""

from __future__ import annotations

import argparse
import concurrent.futures
import difflib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
CASES = ROOT / "tests" / "cases"
GOLDENS = ROOT / "tests" / "goldens"
ROC = os.environ.get("ROC", "roc")


def run_case(source: Path, pandoc: str | None) -> tuple[Path, bytes, str | None]:
	process = subprocess.run(
		[ROC, str(source)],
		cwd=ROOT,
		stdout=subprocess.PIPE,
		stderr=subprocess.PIPE,
		check=False,
	)
	if process.returncode != 0:
		message = process.stderr.decode("utf-8", errors="replace")
		return source, process.stdout, message

	try:
		json.loads(process.stdout)
	except (UnicodeDecodeError, json.JSONDecodeError) as error:
		return source, process.stdout, f"stdout is not valid JSON: {error}"

	if pandoc is not None:
		round_trip = subprocess.run(
			[pandoc, "--from=json", "--to=json"],
			cwd=ROOT,
			input=process.stdout,
			stdout=subprocess.PIPE,
			stderr=subprocess.PIPE,
			check=False,
		)
		if round_trip.returncode != 0:
			message = round_trip.stderr.decode("utf-8", errors="replace")
			return source, process.stdout, f"Pandoc rejected generated JSON:\n{message}"

	return source, process.stdout, None


def show_diff(golden: Path, expected: bytes, actual: bytes) -> str:
	return "".join(
		difflib.unified_diff(
			expected.decode("utf-8", errors="replace").splitlines(keepends=True),
			actual.decode("utf-8", errors="replace").splitlines(keepends=True),
			fromfile=str(golden.relative_to(ROOT)),
			tofile=f"{golden.relative_to(ROOT)} (generated)",
		)
	)


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument(
		"--update",
		action="store_true",
		help="overwrite checked-in JSON goldens with the apps' stdout",
	)
	parser.add_argument(
		"--require-pandoc",
		action="store_true",
		help="fail if Pandoc is unavailable instead of skipping AST validation",
	)
	parser.add_argument(
		"--jobs",
		type=int,
		default=os.cpu_count() or 1,
		help="maximum number of Roc apps to run concurrently",
	)
	args = parser.parse_args()

	if shutil.which(ROC) is None:
		print(f"error: Roc compiler is not available: {ROC}", file=sys.stderr)
		return 2
	pandoc = shutil.which("pandoc")
	if args.require_pandoc and pandoc is None:
		print("error: pandoc is not available on PATH", file=sys.stderr)
		return 2

	sources = sorted(CASES.glob("*.roc"))
	if not sources:
		print(f"error: no Roc test apps found in {CASES}", file=sys.stderr)
		return 2

	with concurrent.futures.ThreadPoolExecutor(max_workers=max(args.jobs, 1)) as pool:
		results = list(pool.map(lambda source: run_case(source, pandoc), sources))

	failed = False
	GOLDENS.mkdir(parents=True, exist_ok=True)
	for source, actual, error in results:
		name = source.stem
		golden = GOLDENS / f"{name}.json"
		if error is not None:
			failed = True
			print(f"FAIL {name}\n{error}", file=sys.stderr)
			continue

		if args.update:
			golden.write_bytes(actual)
			print(f"UPDATE {name}")
		elif not golden.exists():
			failed = True
			print(f"FAIL {name}: missing {golden.relative_to(ROOT)}", file=sys.stderr)
		elif (expected := golden.read_bytes()) != actual:
			failed = True
			print(f"FAIL {name}", file=sys.stderr)
			print(show_diff(golden, expected, actual), file=sys.stderr, end="")
		else:
			print(f"PASS {name}")

	if failed:
		return 1

	if args.update:
		check = subprocess.run(["git", "diff", "--check"], cwd=ROOT, check=False)
		if check.returncode != 0:
			return check.returncode

	print(f"All {len(sources)} golden tests passed.")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
