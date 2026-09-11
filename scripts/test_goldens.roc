#!/usr/bin/env roc-stable
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	ascii: "https://github.com/Hasnep/roc-ascii/releases/download/v0.5.0/5WxqRf15XVko4HxVq5dW8r84s95CxrtvzrjZYwbg9Z3H.tar.zst",
	ansi: "https://github.com/lukewilliamboswell/roc-ansi/releases/download/0.13.0/JXLM47L6CzrLXB5HBfqc27VnU6CD4jMm5Mk6dgbbovL.tar.zst",
	weaver: "https://github.com/lukewilliamboswell/weaver/releases/download/0.9.0/7j6KBFBEZ8pNMLQHkx9xiwyZ2PmwQPgKNDPUih6gKe77.tar.zst",
	roc: "nightly-2026-09-10-a670e34",
}

import cli.Cmd
import cli.OsStr
import cli.Path
import cli.Stderr
import cli.Stdout
import weaver.Cli
import weaver.Opt
import src/Files
import src/Script

main! = |args| {
	# This stable-Roc driver runs each small test application with ROC_NIGHTLY and
	# compares its JSON output with tests/goldens. --update reverses the last step
	# and intentionally replaces the checked-in expected output.
	options = match Cli.parse_or_display_message(cli_parser, args.drop_first(1), OsStr.to_raw) {
		Ok(parsed) => {
			jobs = match parsed.jobs {
				Ok(value) if value > 0 => value
				Ok(_) => return Script.fail!("--jobs must be greater than zero")
				Err(NoValue) => 0
			}
			{ update: parsed.update, require_pandoc: parsed.require_pandoc, jobs }
		}
		Err(Help(message)) | Err(Version(message)) => {
			Stdout.line!(message)?
			return Ok({})
		}
		Err(InvalidUsage(message)) => {
			Stderr.line!(message)?
			return Err(InvalidCommandLine)
		}
	}
	roc_nightly = Script.roc_nightly!()?
	pandoc_available = Cmd.check_available!("pandoc")
	if options.require_pandoc and !pandoc_available {
		return Script.fail!("pandoc is not available on PATH")
	}

	cases = Files.direct_roc_files!("tests/cases")?
	if cases.len() == 0 {
		return Script.fail!("no Roc test apps found in tests/cases")
	}

	case_names = cases.map(|path| Files.stem(Path.filename(path).map_ok(Path.display) ?? ""))
	goldens = Path.list!("tests/goldens")?
	for golden in goldens {
		name = Files.stem(Path.filename(golden).map_ok(Path.display) ?? "")
		if !case_names.contains(name) {
			return Script.fail!("orphaned golden without a test case: ${Path.display(golden)}")
		}
	}

	run_cases!(cases, options.jobs, roc_nightly, pandoc_available, options.update)?

	if options.update {
		Script.command("git").run!(["diff", "--check"])?
	}
	Stdout.line!("All ${cases.len().to_str()} golden tests passed.")
}

run_cases! = |remaining, jobs, roc_nightly, pandoc_available, update| {
	if remaining.len() == 0 {
		return Ok({})
	}
	batch_size = if jobs == 0 or jobs > remaining.len() remaining.len() else jobs
	# Start one batch together before waiting, which provides bounded parallelism
	# without hiding process ownership in a separate scheduler.
	batch = List.sublist(remaining, { start: 0, len: batch_size })
	processes = spawn_cases!(batch, roc_nightly, [])?
	for (source, child) in processes {
		filename = Path.filename(source).map_ok(Path.display).map_err(|_| InvalidCasePath(Path.display(source)))?
		name = Files.stem(filename)
		actual = Script.wait_capture!(child)?
		if pandoc_available {
			_ = Script.run_capture!(Cmd.new("pandoc"), ["--from=json", "--to=json"], ".", actual)?
		}
		golden : Path
		golden = "tests/goldens/${name}.json"
		if update {
			Path.write_bytes!(golden, actual)?
			Script.update!(name)?
		} else if !Path.is_file!(golden)? {
			return Script.fail!("${name}: missing ${Path.display(golden)}")
		} else if Path.read_bytes!(golden)? != actual {
			return Script.fail!("golden output mismatch: ${name}")
		} else {
			Script.pass!(name)?
		}
	}
	run_cases!(remaining.drop_first(batch_size), jobs, roc_nightly, pandoc_available, update)
}

spawn_cases! = |cases, roc_nightly, spawned|
	match cases {
		[source, .. as rest] => {
			child = roc_nightly.spawn!([Path.to_os_str(source)], ".")?
			spawn_cases!(rest, roc_nightly, spawned.append((source, child)))
		}
		[] => Ok(spawned)
	}

TestOptions : { update : Bool, require_pandoc : Bool, jobs : Try(U64, [NoValue]) }

cli_parser : Cli.CliParser(TestOptions)
cli_parser =
	Cli.assert_valid(
		Cli.finish(
			{
				update: Opt.flag({
					short: "",
					long: "update",
					help: "Overwrite checked-in JSON goldens with generated output.",
				}),
				require_pandoc: Opt.flag({
					short: "",
					long: "require-pandoc",
					help: "Fail if Pandoc is unavailable instead of skipping AST validation.",
				}),
				jobs: Opt.maybe_u64({
					short: "j",
					long: "jobs",
					help: "Maximum number of Roc test apps to run concurrently.",
				}),
			}.Cli,
			{
				name: "roc-pandoc-test",
				version: "development",
				authors: [],
				description: "Run Roc golden apps and compare or regenerate their JSON output.",
				text_style: Plain,
			},
		),
	)
