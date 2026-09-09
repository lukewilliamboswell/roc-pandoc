#!/usr/bin/env python3
"""Test the golden applications against a packaged release bundle."""

from __future__ import annotations

import argparse
import functools
import http.server
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import threading


ROOT = Path(__file__).resolve().parents[1]
DEPENDENCY_RE = re.compile(r'(\bpandoc:\s*)"[^"]+"')


def run(
	command: list[str], *, cwd: Path, input_text: str | None = None
) -> subprocess.CompletedProcess[str]:
	print("+", " ".join(command), flush=True)
	completed = subprocess.run(
		command, cwd=cwd, text=True, input=input_text, capture_output=True, check=False
	)
	if completed.returncode:
		print(completed.stdout, end="")
		print(completed.stderr, end="", file=sys.stderr)
		raise SystemExit(completed.returncode)
	return completed


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--bundle-path", type=Path, required=True)
	args = parser.parse_args()
	bundle_path = args.bundle_path.resolve()
	if not bundle_path.is_file():
		raise SystemExit(f"Bundle does not exist: {bundle_path}")

	with tempfile.TemporaryDirectory(prefix="roc-pandoc-bundle-") as temporary:
		tmp = Path(temporary)
		served_bundle = tmp / bundle_path.name
		shutil.copy2(bundle_path, served_bundle)
		cases = tmp / "cases"
		shutil.copytree(ROOT / "tests" / "cases", cases)

		handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(tmp))
		server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
		threading.Thread(target=server.serve_forever, daemon=True).start()
		try:
			bundle_url = f"http://127.0.0.1:{server.server_port}/{served_bundle.name}"
			for case in sorted(cases.glob("*.roc")):
				source, count = DEPENDENCY_RE.subn(lambda match: f'{match.group(1)}"{bundle_url}"', case.read_text(encoding="utf-8"), count=1)
				if count != 1:
					raise SystemExit(f"{case.name} does not declare the pandoc dependency")
				case.write_text(source, encoding="utf-8")
				completed = run([os.environ.get("ROC", "roc"), case.name, "--no-cache"], cwd=cases)
				expected = (ROOT / "tests" / "goldens" / f"{case.stem}.json").read_text(encoding="utf-8")
				if completed.stdout != expected:
					raise SystemExit(f"Golden output mismatch for {case.name}")
				run(
					["pandoc", "--from=json", "--to=json"],
					cwd=cases,
					input_text=completed.stdout,
				)
		finally:
			server.shutdown()
			server.server_close()
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
