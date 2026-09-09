#!/usr/bin/env python3
"""Point every example app at a newly published roc-pandoc bundle."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
DEPENDENCY_RE = re.compile(r'(\bpandoc:\s*)"([^"]+)"')
RELEASE_VERSION_RE = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?")
ARTIFACT_RE = re.compile(r"[A-Za-z0-9._-]+\.tar\.zst")
REPOSITORY_RE = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+")


def bundle_url(*, repository: str, release_version: str, artifact_file: str) -> str:
	if not REPOSITORY_RE.fullmatch(repository):
		raise ValueError(f"Invalid GitHub repository: {repository!r}")
	if not RELEASE_VERSION_RE.fullmatch(release_version):
		raise ValueError(f"Invalid release version: {release_version!r}")
	if not ARTIFACT_RE.fullmatch(artifact_file):
		raise ValueError(f"Invalid bundle artifact filename: {artifact_file!r}")
	return f"https://github.com/{repository}/releases/download/{release_version}/{artifact_file}"


def artifact_from_manifest(path: Path) -> str:
	try:
		manifest = json.loads(path.read_text(encoding="utf-8"))
	except (OSError, json.JSONDecodeError) as error:
		raise ValueError(f"Could not read release bundle manifest {path}: {error}") from error
	if not isinstance(manifest, list) or len(manifest) != 1:
		raise ValueError("Expected exactly one release bundle")
	artifact = manifest[0].get("artifact_file") if isinstance(manifest[0], dict) else None
	if not isinstance(artifact, str):
		raise ValueError("Release bundle manifest has no artifact_file")
	return artifact


def update_examples(examples_dir: Path, url: str) -> list[Path]:
	updated: list[Path] = []
	app_roots: list[Path] = []
	for path in sorted(examples_dir.rglob("*.roc")):
		source = path.read_text(encoding="utf-8")
		if not re.search(r"(?m)^app\s", source):
			continue
		app_roots.append(path)
		rewritten, count = DEPENDENCY_RE.subn(lambda match: f'{match.group(1)}"{url}"', source)
		if count != 1:
			raise ValueError(f"Expected exactly one pandoc dependency in {path}")
		if rewritten != source:
			path.write_text(rewritten, encoding="utf-8")
			updated.append(path)
	if not app_roots:
		raise ValueError(f"No example app roots found under {examples_dir}")
	return updated


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--release-version", required=True)
	parser.add_argument("--release-list-file", type=Path, required=True)
	parser.add_argument("--repository", default="lukewilliamboswell/roc-pandoc")
	parser.add_argument("--examples-dir", type=Path, default=ROOT / "examples")
	args = parser.parse_args()

	artifact = artifact_from_manifest(args.release_list_file)
	url = bundle_url(
		repository=args.repository,
		release_version=args.release_version,
		artifact_file=artifact,
	)
	updated = update_examples(args.examples_dir, url)
	print(f"Pinned {len(updated)} example app roots to {url}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
