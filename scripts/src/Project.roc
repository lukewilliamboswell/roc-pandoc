import ascii.Ascii
import cli.Env
import cli.Path exposing [Path]
import Release

## Repository paths, defaults, and working-tree discovery for the scripts.
Project := [].{

	## A path relative to the repository root, stored as validated segments.
	RepoPath := { segments : List(Str) }.{

		## Resolve this repository-relative path against an absolute root path.
		resolve : RepoPath, Path -> Path
		resolve = |repo_path, root| repo_path.segments.fold(root, |path, segment| Path.join(path, segment))
	}

	## Important paths discovered for a roc-pandoc working tree.
	Workspace := {
		root : Path,
		package_dir : Path,
		package_entry : Path,
		examples_dir : Path,
	}.{}

	## Checked-in repository layout and release defaults shared by all scripts.
	config = {
		package_dir: RepoPath.{ segments: ["package"] },
		package_entry: RepoPath.{ segments: ["package", "main.roc"] },
		examples_dir: RepoPath.{ segments: ["examples"] },
		default_output_dir: RepoPath.{ segments: ["dist"] },
		default_repository: Release.Repository.("lukewilliamboswell/roc-pandoc"),
	}

	## Discover the current repository root and verify its expected package and examples.
	init! : () => Try(Workspace, _)
	init! = || {
		root = Env.cwd!()?
		package_entry = config.package_entry.resolve(root)
		examples_dir = config.examples_dir.resolve(root)
		if !Path.is_file!(package_entry)? or !Path.is_dir!(examples_dir)? {
			return Err(NotRepositoryRoot(Path.display(root)))
		}
		Ok(
			Workspace.{
				root,
				package_dir: config.package_dir.resolve(root),
				package_entry,
				examples_dir,
			},
		)
	}
}

valid_segment = |segment|
	segment != ""
		and segment != "."
			and segment != ".."
				and !segment.contains("/")
					and !segment.contains("\\")
						and Ascii.from_str(segment).is_ok()

valid_repo_path = |repo_path| !repo_path.segments.is_empty() and repo_path.segments.all(valid_segment)

expect valid_repo_path(Project.config.package_dir)
expect valid_repo_path(Project.config.package_entry)
expect valid_repo_path(Project.config.examples_dir)
expect valid_repo_path(Project.config.default_output_dir)
expect Release.Repository.from_str(Project.config.default_repository.to_str()).is_ok()
