import Release

## Pure parsing and source-rewriting helpers for updating example package pins.
UpdatePins := [].{

	## A source file paired with the caller-defined path used to identify it.
	SourceFile(path) := { path : path, source : Str }.{}

	## A replacement file body paired with the caller-defined destination path.
	Edit(path) := { path : path, content : Str }.{}

	## Parse the release workflow manifest and require exactly one bundle asset.
	artifact_from_manifest : Str -> Try(Release.ArtifactFile, _)
	artifact_from_manifest = |json| {
		manifest : List({ artifact_file : Str })
		manifest = Json.parse(json).map_err(|err| InvalidBundleManifest(err))?
		match manifest {
			[{ artifact_file }] => Release.ArtifactFile.from_str(artifact_file).map_err(|_| InvalidBundleManifestArtifact)
			_ => Err(ExpectedOneReleaseBundle)
		}
	}

	## Return only source files that change when pinned to `url`.
	edits : List(SourceFile(path)), Release.PackageUrl -> Try(List(Edit(path)), _)
	edits = |sources, url| {
		if sources.is_empty() {
			return Err(NoExampleAppRoots)
		}
		edits_help(sources, url, [])
	}

	## Replace the single `pandoc:` package URL in a Roc application header.
	rewrite_source : Str, Release.PackageUrl -> Try(Str, _)
	rewrite_source = |source, url| {
		parts = Str.split_on(source, "pandoc:")
		match parts {
			[before, after] =>
				match Str.split_on(after, "\"") {
					[prefix, _, .. as suffix] => Ok("${before}pandoc:${prefix}\"${url.to_str()}\"${Str.join_with(suffix, "\"")}")
					_ => Err(InvalidPandocDependency)
				}
			_ => Err(ExpectedOnePandocDependency)
		}
	}
}

edits_help = |sources, url, edits|
	match sources {
		[source_file, .. as rest] => {
			rewritten = UpdatePins.rewrite_source(source_file.source, url)?
			next = if rewritten == source_file.source edits else edits.append(UpdatePins.Edit.{ path: source_file.path, content: rewritten })
			edits_help(rest, url, next)
		}
		[] => Ok(edits)
	}

expect UpdatePins.artifact_from_manifest("[{\"artifact_file\":\"abc.tar.zst\"}]").is_ok()
expect UpdatePins.artifact_from_manifest("[{}]").is_err()
expect match UpdatePins.artifact_from_manifest("[{\"artifact_file\":\"a.tar.zst\"},{\"artifact_file\":\"b.tar.zst\"}]") {
	Err(ExpectedOneReleaseBundle) => Bool.True
	_ => Bool.False
}
expect {
	repository = Release.Repository.from_str("owner/repo")?
	version = Release.Version.from_str("1.2.3-rc.1")?
	artifact = Release.ArtifactFile.from_str("abc.tar.zst")?
	url = Release.PackageUrl.release(repository, version, artifact)
	edits = UpdatePins.edits(
		[
			UpdatePins.SourceFile.{ path: "hello.roc", source: "app [main!] { pandoc: \"old\" }\n" },
			UpdatePins.SourceFile.{ path: "report/main.roc", source: "app [main!] { pandoc: \"old\" }\n" },
		],
		url,
	)?
	edits.len() == 2
}
expect {
	repository = Release.Repository.from_str("owner/repo")?
	version = Release.Version.from_str("1.2.3")?
	artifact = Release.ArtifactFile.from_str("abc.tar.zst")?
	url = Release.PackageUrl.release(repository, version, artifact)
	source = "app [main!] { pandoc: \"${url.to_str()}\" }\n"
	edits = UpdatePins.edits([UpdatePins.SourceFile.{ path: "main.roc", source }], url)?
	edits.is_empty()
}
expect {
	repository = Release.Repository.from_str("owner/repo")?
	version = Release.Version.from_str("1.2.3")?
	artifact = Release.ArtifactFile.from_str("abc.tar.zst")?
	url = Release.PackageUrl.release(repository, version, artifact)
	match UpdatePins.edits([], url) {
		Err(NoExampleAppRoots) => Bool.True
		_ => Bool.False
	}
}
expect {
	repository = Release.Repository.from_str("owner/repo")?
	version = Release.Version.from_str("1.2.3")?
	artifact = Release.ArtifactFile.from_str("abc.tar.zst")?
	url = Release.PackageUrl.release(repository, version, artifact)
	match UpdatePins.edits(
		[
			UpdatePins.SourceFile.{ path: "good.roc", source: "app [main!] { pandoc: \"old\" }\n" },
			UpdatePins.SourceFile.{ path: "bad.roc", source: "app [main!] {}\n" },
		],
		url,
	) {
		Err(ExpectedOnePandocDependency) => Bool.True
		_ => Bool.False
	}
}
