#!/usr/bin/env python3
"""Run every repository check used by CI."""

from __future__ import annotations

import concurrent.futures
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import zipfile


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


WORKFLOW_OUTPUTS = {
	"ebook": "field-notes.epub",
	"office-report": "quarterly-report.docx",
	"research-summary": "research.html",
	"slide-deck": "demo-day.pptx",
	"technical-paper": "paper.tex",
	"web-page": "product.html",
}

HTML_TITLES = {
	"product.html": "Acorn task manager",
	"research.html": "Functional build design: research summary",
}


def validate_artifact(path: Path) -> None:
	if not path.is_file() or path.stat().st_size == 0:
		raise ValueError(f"missing or empty output: {path.name}")

	if path.suffix in {".epub", ".docx", ".pptx"}:
		if not zipfile.is_zipfile(path):
			raise ValueError(f"{path.name} is not a valid ZIP-based document")
		with zipfile.ZipFile(path) as archive:
			bad_member = archive.testzip()
			if bad_member is not None:
				raise ValueError(f"{path.name} has a corrupt member: {bad_member}")
	elif path.suffix == ".html":
		html = path.read_text(encoding="utf-8")
		expected_title = HTML_TITLES[path.name]
		if f"<title>{expected_title}</title>" not in html:
			raise ValueError(f"{path.name} does not have the expected HTML title")
	elif path.suffix == ".tex":
		latex = path.read_text(encoding="utf-8")
		if "\\begin{document}" not in latex or "\\end{document}" not in latex:
			raise ValueError(f"{path.name} is not a standalone LaTeX document")

	json_path = path.with_name(f"{path.name}.pandoc.json")
	with json_path.open(encoding="utf-8") as source:
		ast = json.load(source)
	if not isinstance(ast.get("blocks"), list) or not ast["blocks"]:
		raise ValueError(f"{json_path.name} has no Pandoc blocks")


def run_workflow_examples() -> int:
	"""Execute showcase apps in a copy so generated documents never dirty the checkout."""
	with tempfile.TemporaryDirectory(prefix="roc-pandoc-examples-") as temporary:
		temp_root = Path(temporary)
		shutil.copytree(ROOT / "package", temp_root / "package")
		shutil.copytree(ROOT / "examples", temp_root / "examples")

		for workflow, output_name in WORKFLOW_OUTPUTS.items():
			workdir = temp_root / "examples" / workflow
			print(f"\n$ (cd examples/{workflow} && {ROC} main.roc --no-cache)", flush=True)
			completed = subprocess.run([ROC, "main.roc", "--no-cache"], cwd=workdir, check=False)
			if completed.returncode:
				return completed.returncode
			try:
				validate_artifact(workdir / output_name)
			except (OSError, ValueError, zipfile.BadZipFile, json.JSONDecodeError) as error:
				print(f"FAIL examples/{workflow}: {error}", file=sys.stderr)
				return 1
			print(f"PASS examples/{workflow}/{output_name}")
	return 0


def main() -> int:
	if run([sys.executable, "scripts/test_update_example_package_pins.py"]):
		return 1
	if run([ROC, "fmt", "--check", "package", "examples", "tests/cases"]):
		return 1
	if run([ROC, "check", "package/main.roc", "--no-cache"]):
		return 1
	if run([sys.executable, "scripts/test.py", "--require-pandoc"]):
		return 1

	# Capitalized files are support modules checked through the apps that import them.
	examples = sorted(path for path in (ROOT / "examples").glob("*.roc") if path.name[0].islower())
	examples += sorted((ROOT / "examples").glob("*/main.roc"))
	with concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count() or 1) as pool:
		for path, status in pool.map(check_example, examples):
			print(f"{'PASS' if status == 0 else 'FAIL'} {path.relative_to(ROOT)}")
			if status:
				return status

	if run_workflow_examples():
		return 1

	with tempfile.TemporaryDirectory(prefix="roc-pandoc-docs-") as output:
		if run([ROC, "docs", "package/main.roc", f"--output={output}", "--no-cache"]):
			return 1

	return run(["git", "diff", "--check"])


if __name__ == "__main__":
	raise SystemExit(main())
