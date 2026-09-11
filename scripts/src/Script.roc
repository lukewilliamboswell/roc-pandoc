import cli.Cmd
import cli.Env
import cli.OsStr
import cli.Path
import cli.Stderr
import cli.Stdout
import ansi.ANSI

## Shared command, environment, error, and terminal-output helpers for scripts.
Script := [].{

	## A command-line program with receiver methods used by repository scripts.
	Command := { base : Cmd, program : OsStr }.{

		## Print a concise `RUN` heading, append arguments, and execute the command.
		run! : Command, List(OsStr) => Try({}, _)
		run! = |self, args| {
			command = self.base.args(args)
			display = Str.join_with([self.program].concat(args).map(OsStr.display), " ")
			Stdout.line!("\n${heading("RUN", Cyan)} ${display}")?
			command.exec_cmd!()
		}

		## Run in `cwd` with byte input and return captured standard output.
		capture! = |self, args, cwd, stdin|
			run_capture!(self.base, args, cwd, stdin)

		## Spawn in `cwd` with standard output and error captured for later waiting.
		spawn! = |self, args, cwd|
			spawn_capture!(self.base, args, cwd)

		## Build the underlying basic-cli command with the supplied arguments.
		cmd : Command, List(OsStr) -> Cmd
		cmd = |self, args| self.base.args(args)
	}

	## Construct a script command from a program name or path.
	command : OsStr -> Command
	command = |program| Command.{ base: Cmd.new(program), program }

	## Resolve the stable tooling compiler from `ROC_STABLE`, falling back to `roc`.
	roc_stable! : () => Try(Command, _)
	roc_stable! = || {
		match Env.var!("ROC_STABLE") {
			Ok(value) => Ok(Script.command(value))
			Err(VarNotFound(_)) => Ok(Script.command("roc"))
			Err(err) => Err(EnvironmentInputError("ROC_STABLE", err))
		}
	}

	## Resolve the development compiler from `ROC_NIGHTLY`, falling back to `roc`.
	roc_nightly! : () => Try(Command, _)
	roc_nightly! = || {
		match Env.var!("ROC_NIGHTLY") {
			Ok(value) => Ok(Script.command(value))
			Err(VarNotFound(_)) => Ok(Script.command("roc"))
			Err(err) => Err(EnvironmentInputError("ROC_NIGHTLY", err))
		}
	}

	## Read a required UTF-8 environment variable with a script-level error.
	env_str! : OsStr => Try(Str, _)
	env_str! = |name|
		Env.var_str!(name)
			.map_err(|err| EnvironmentInputError(OsStr.display(name), err))

	## Read a UTF-8 environment variable, using `fallback` when it is absent.
	env_str_or! : OsStr, Str => Try(Str, _)
	env_str_or! = |name, fallback|
		match Env.var_str!(name) {
			Ok(value) => Ok(value)
			Err(VarNotFound(_)) => Ok(fallback)
			Err(err) => Err(EnvironmentInputError(OsStr.display(name), err))
		}

	## Read a required UTF-8 environment variable as a filesystem path.
	env_path! : OsStr => Try(Path, _)
	env_path! = |name| Script.env_str!(name).map_ok(Path.utf8)

	## Read an environment variable as a path, using `fallback` when absent.
	env_path_or! : OsStr, Path => Try(Path, _)
	env_path_or! = |name, fallback|
		Script.env_str_or!(name, Path.display(fallback)).map_ok(Path.utf8)

	## Read the UTF-8 file named by a required environment variable.
	read_env_utf8! : OsStr => Try(Str, _)
	read_env_utf8! = |name| Path.read_utf8!(Script.env_path!(name)?)

	## Print a green `PASS` result followed by its description.
	pass! : Str => Try({}, _)
	pass! = |message| Stdout.line!("${heading("PASS", Green)} ${message}")

	## Print a yellow `UPDATE` result followed by its description.
	update! : Str => Try({}, _)
	update! = |message| Stdout.line!("${heading("UPDATE", Yellow)} ${message}")

	## Print a cyan informational label followed by its description.
	info! : Str, Str => Try({}, _)
	info! = |label, message| Stdout.line!("${heading(label, Cyan)} ${message}")

	## Run a basic-cli command with byte input and return captured standard output.
	run_capture! = |base, args, cwd, stdin| {
		output = base
			.args(args)
			.cwd(cwd)
			.stdin(Bytes(stdin))
			.run!()
			.map_err(|err| CommandRunFailed(err))?
		match output.status {
			Exited(0) => Ok(output.stdout_bytes)
			Exited(code) => {
				Stderr.write_bytes!(output.stderr_bytes)?
				Err(CommandExited(code))
			}
			Signaled(signal) => {
				Stderr.write_bytes!(output.stderr_bytes)?
				Err(CommandSignaled(signal))
			}
		}
	}

	## Spawn a basic-cli command with standard output and error captured.
	spawn_capture! = |base, args, cwd| {
		base
			.args(args)
			.cwd(cwd)
			.stdout(Capture)
			.stderr(Capture)
			.spawn!()
			.map_err(|err| CommandSpawnFailed(err))
	}

	## Wait for a captured child, returning stdout or reporting its failure.
	wait_capture! = |child| {
		output = child.wait!().map_err(|err| CommandWaitFailed(err))?
		match output.status {
			Exited(0) => Ok(output.stdout_bytes)
			Exited(code) => {
				Stderr.write_bytes!(output.stderr_bytes)?
				Err(CommandExited(code))
			}
			Signaled(signal) => {
				Stderr.write_bytes!(output.stderr_bytes)?
				Err(CommandSignaled(signal))
			}
		}
	}

	## Print a script error and return `ScriptFailed`.
	fail! : Str => Try({}, _)
	fail! = |message| {
		Stderr.line!("error: ${message}")?
		Err(ScriptFailed)
	}

	## Require an existing regular file or report a readable script error.
	require_file! : Path => Try({}, _)
	require_file! = |path|
		if Path.is_file!(path)? {
			Ok({})
		} else {
			fail!("file does not exist: ${Path.display(path)}")
		}
}

heading = |label, color|
	ANSI.color(label, { fg: Standard(color), bg: Default })
