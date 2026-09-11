#!/usr/bin/env roc-stable
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	ascii: "https://github.com/Hasnep/roc-ascii/releases/download/v0.5.0/5WxqRf15XVko4HxVq5dW8r84s95CxrtvzrjZYwbg9Z3H.tar.zst",
	ansi: "https://github.com/lukewilliamboswell/roc-ansi/releases/download/0.13.0/JXLM47L6CzrLXB5HBfqc27VnU6CD4jMm5Mk6dgbbovL.tar.zst",
	roc: "nightly-2026-09-10-a670e34",
}

import cli.Path
import src/Files
import src/Project
import src/Release
import src/Script
import src/UpdatePins

main! = |_args| {
	# After GitHub publishes a release, this script reads its asset manifest and
	# rewrites every example to use the immutable package URL for that exact asset.
	# The workflow provides release-specific values through environment variables.
	workspace = Project.init!()?
	release_version = Script.env_str!("RELEASE_VERSION")?
	repository = Script.env_str_or!("REPOSITORY", Project.config.default_repository.to_str())?
	examples_dir = Script.env_path_or!("EXAMPLES_DIR", workspace.examples_dir)?
	manifest = Script.read_env_utf8!("RELEASE_LIST_FILE")?
	artifact = UpdatePins.artifact_from_manifest(manifest)?
	typed_repository = Release.Repository.from_str(repository)?
	typed_version = Release.Version.from_str(release_version)?
	release_url = Release.PackageUrl.release(typed_repository, typed_version, artifact)
	app_sources = Files.app_sources!(examples_dir)?
	sources = app_sources.map(|source| UpdatePins.SourceFile.{ path: source.path, source: source.source })
	edits = UpdatePins.edits(sources, release_url)?
	for edit in edits {
		Path.write_utf8!(edit.path, edit.content)?
	}
	Script.update!("pinned ${edits.len().to_str()} example app roots to ${release_url.to_str()}")
}
