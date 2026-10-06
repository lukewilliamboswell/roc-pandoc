#!/usr/bin/env roc-stable
app [main!] {
	ansi: "https://github.com/lukewilliamboswell/roc-ansi/releases/download/0.13.0/JXLM47L6CzrLXB5HBfqc27VnU6CD4jMm5Mk6dgbbovL.tar.zst",
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.24.0/AEjfyaMFFbh8FJrkkHJy68riVNPr3Qp6c6PawWQjBwMH.tar.zst",
	roc: "nightly-2026-10-04-130536d",
}

import cli.Cmd
import cli.OsStr
import cli.Path
import src/Files
import src/Project
import src/Script

main! = |_args| {
	# CI supplies OUTPUT_DIR; local runs default to dist/ under the repository root.
	# Bundles are deliberately built with nightly because they contain the package
	# being developed, while this script itself runs on stable Roc.
	workspace = Project.init!()?
	roc_nightly = Script.roc_nightly!()?
	output = Script.env_path_or!("OUTPUT_DIR", Project.config.default_output_dir.resolve(workspace.root))?
	absolute_output = Path.absolute!(output)?
	package_files = Files.sort_paths(Files.direct_roc_files!(workspace.package_dir)?)?
	package_modules = package_files.map_try(
		|path|
			Path.filename(path)
				.map_ok(Path.display)
				.map_err(|_| InvalidPackageModulePath(Path.display(path))),
	)?
	if !package_modules.contains("main.roc") {
		return Err(MissingPackageEntrypoint)
	}

	# Roc bundle takes the package root first, followed by each exposed module.
	module_args = package_modules
		.keep_if(|filename| filename != "main.roc")
		.map(OsStr.from_str)
	bundle_args = ["bundle", "main.roc"]
		.concat(module_args)
		.concat(["--output-dir", Path.to_os_str(absolute_output)])

	Path.create_all!(absolute_output)?
	roc_nightly
		.cmd(bundle_args)
		.cwd(workspace.package_dir)
		.exec_cmd!()
}
