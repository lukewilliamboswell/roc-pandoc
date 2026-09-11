## Validated values used to construct roc-pandoc release package URLs.
Release := [].{

	## A GitHub repository identifier in `owner/name` form.
	Repository := Str.{

		## Validate and construct a GitHub repository identifier.
		from_str : Str -> Try(Repository, _)
		from_str = |value| if valid_repository(value) Ok(Repository.(value)) else Err(InvalidRepository(value))

		## Return the validated `owner/name` string.
		to_str : Repository -> Str
		to_str = |Repository.(value)| value
	}

	## A semantic release version such as `1.2.3` or `1.2.3-rc.1`.
	Version := Str.{

		## Validate and construct a release version.
		from_str : Str -> Try(Version, _)
		from_str = |value| if valid_version(value) Ok(Version.(value)) else Err(InvalidReleaseVersion(value))

		## Return the validated release version string.
		to_str : Version -> Str
		to_str = |Version.(value)| value
	}

	## The filename of a `.tar.zst` release bundle asset.
	ArtifactFile := Str.{

		## Validate and construct a release bundle filename.
		from_str : Str -> Try(ArtifactFile, _)
		from_str = |value| if valid_artifact(value) Ok(ArtifactFile.(value)) else Err(InvalidArtifact(value))

		## Return the validated artifact filename.
		to_str : ArtifactFile -> Str
		to_str = |ArtifactFile.(value)| value
	}

	## A package URL suitable for a Roc dependency declaration.
	PackageUrl := Str.{

		## Construct the immutable GitHub URL for a published release bundle.
		release : Repository, Version, ArtifactFile -> PackageUrl
		release = |repository, version, artifact| PackageUrl.("https://github.com/${repository.to_str()}/releases/download/${version.to_str()}/${artifact.to_str()}")

		## Construct a localhost URL used while testing an unpublished bundle.
		localhost : U16, Str -> Try(PackageUrl, _)
		localhost = |port, artifact_file| {
			artifact = ArtifactFile.from_str(artifact_file)?
			Ok(PackageUrl.("http://127.0.0.1:${port.to_str()}/${artifact.to_str()}"))
		}

		## Return the validated package URL string.
		to_str : PackageUrl -> Str
		to_str = |PackageUrl.(value)| value
	}
}

valid_repository = |value|
	match Str.split_on(value, "/") {
		[owner, repo] => owner.to_utf8().len() > 0 and repo.to_utf8().len() > 0 and valid_token(owner) and valid_token(repo)
		_ => Bool.False
	}

valid_version = |value| valid_version_bytes(value.to_utf8(), { dots: 0, component_has_digit: Bool.False, prerelease: Bool.False, prerelease_has_char: Bool.False })

valid_version_bytes = |bytes, state|
	match bytes {
		[] => state.dots == 2 and state.component_has_digit and (!state.prerelease or state.prerelease_has_char)
		[byte, .. as rest] if state.prerelease => if version_token_byte(byte) valid_version_bytes(rest, { ..state, prerelease_has_char: Bool.True }) else Bool.False
		[byte, .. as rest] if byte >= '0' and byte <= '9' => valid_version_bytes(rest, { ..state, component_has_digit: Bool.True })
		['.', .. as rest] if state.component_has_digit and state.dots < 2 => valid_version_bytes(rest, { ..state, dots: state.dots + 1, component_has_digit: Bool.False })
		['-', .. as rest] if state.component_has_digit and state.dots == 2 => valid_version_bytes(rest, { ..state, prerelease: Bool.True })
		_ => Bool.False
	}

valid_artifact = |value| {
	suffix = ".tar.zst"
	value.to_utf8().len() > suffix.to_utf8().len() and value.ends_with(suffix) and valid_token(value)
}

valid_token = |value| Str.to_utf8(value).all(token_byte)

token_byte = |byte|
	(byte >= 'a' and byte <= 'z') or (byte >= 'A' and byte <= 'Z') or (byte >= '0' and byte <= '9') or byte == '-' or byte == '_' or byte == '.'

version_token_byte = |byte|
	(byte >= 'a' and byte <= 'z') or (byte >= 'A' and byte <= 'Z') or (byte >= '0' and byte <= '9') or byte == '-' or byte == '.'

expect Release.Repository.from_str("owner/repo").is_ok()
expect Release.Repository.from_str("owner/repo/extra").is_err()
expect Release.Version.from_str("1.2.3").is_ok()
expect Release.Version.from_str("1.2.3-rc.1").is_ok()
expect Release.Version.from_str("v1.2.3").is_err()
expect Release.Version.from_str("1.2.3-rc_1").is_err()
expect Release.ArtifactFile.from_str("abc.tar.zst").is_ok()
