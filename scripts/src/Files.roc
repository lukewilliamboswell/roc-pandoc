import cli.Path

## Deterministic filesystem discovery helpers for repository automation.
Files := [].{

	## List the `.roc` files immediately inside `directory`, sorted by ASCII path.
	direct_roc_files! = |directory| {
		entries = Path.list!(directory)?
		sort_paths(entries |> List.keep_if(|path| Path.ext(path).map_ok(Path.display) == Ok("roc")))
	}

	## Recursively find Roc application roots and return each path with its source.
	app_sources! = |directory| find_apps!(Path.list!(directory)?, [])

	## Recursively find Roc application root paths in deterministic order.
	app_roots! = |directory| {
		sources = app_sources!(directory)?
		Ok(sources.map(|source| source.path))
	}

	## Return the part of a filename before its first dot.
	stem = |filename|
		match Str.split_on(filename, ".") {
			[first, ..] => first
			[] => filename
		}

	## Sort repository paths bytewise, rejecting non-ASCII paths.
	sort_paths : List(Path) -> Try(List(Path), _)
	sort_paths = |paths| {
		keyed = paths.map_try(
			|path| {
				key = Str.to_utf8(Path.display(path))
				if key.all(|byte| byte < 128) Ok((key, path)) else Err(NonAsciiRepositoryPath(Path.display(path)))
			},
		)?
		Ok(
			List.sort_with(keyed, |(left, _), (right, _)| compare_bytes(left, right))
				|> List.map(|(_, path)| path),
		)
	}
}

compare_bytes = |left, right|
	match (left, right) {
		([a, .. as left_rest], [b, .. as right_rest]) =>
			if a < b LT else if a > b GT else compare_bytes(left_rest, right_rest)
		([], []) => EQ
		([], _) => LT
		(_, []) => GT
	}

find_apps! = |entries, found|
	match entries {
		[path, .. as rest] =>
			match Path.type!(path)? {
				IsDir => find_apps!(rest, found.concat(Files.app_sources!(path)?))
				IsFile if Path.ext(path).map_ok(Path.display) == Ok("roc") => {
					source = Path.read_utf8!(path)?
					find_apps!(rest, if source.contains("app ") found.append({ path, source }) else found)
				}
				_ => find_apps!(rest, found)
			}
		[] => sort_sources(found)
	}

sort_sources = |sources| {
	paths = Files.sort_paths(sources.map(|source| source.path))?
	Ok(
		paths.map_try(
			|path|
				match sources.find_first(|source| source.path == path) {
					Ok(source) => Ok(source)
					Err(_) => Err(MissingSortedSource(Path.display(path)))
				},
		)?,
	)
}
