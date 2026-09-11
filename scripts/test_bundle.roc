#!/usr/bin/env roc-stable
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	ascii: "https://github.com/Hasnep/roc-ascii/releases/download/v0.5.0/5WxqRf15XVko4HxVq5dW8r84s95CxrtvzrjZYwbg9Z3H.tar.zst",
	ansi: "https://github.com/lukewilliamboswell/roc-ansi/releases/download/0.13.0/JXLM47L6CzrLXB5HBfqc27VnU6CD4jMm5Mk6dgbbovL.tar.zst",
	roc: "nightly-2026-09-10-a670e34",
}

import cli.Cmd
import cli.Env
import cli.OsStr
import cli.Path
import cli.Stderr
import cli.Tcp
import src/Files
import src/Release
import src/Script
import src/UpdatePins

main! = |_args| {
	# The release workflow passes the exact archive it plans to publish. Testing
	# this file catches packaging errors that source-tree checks cannot see.
	bundle = Script.env_path!("BUNDLE_PATH")?
	Script.require_file!(bundle)?
	bundle_bytes = Path.read_bytes!(bundle)?
	bundle_name = Path.filename(bundle).map_ok(Path.display).map_err(|_| InvalidBundlePath(Path.display(bundle)))?
	roc_nightly = Script.roc_nightly!()?

	Env.with_temp_dir!(
		|temporary| {
			# Roc package dependencies are fetched by URL, so serve the candidate archive
			# locally and rewrite only temporary copies of the golden applications.
			cases = prepare_cases!(temporary)?
			listener = Tcp.listen!("127.0.0.1", 0, 5_000)?
			port = listener.local_port!()?
			url = Release.PackageUrl.localhost(port, bundle_name)?
			Script.info!("SERVE", url.to_str())?
			for case in Files.direct_roc_files!(cases)? {
				test_case_against_bundle!(case, cases, url, roc_nightly, listener, bundle_bytes)?
			}
			listener.close!()?
			Ok({})
		},
	)
}

prepare_cases! = |temporary| {
	cases = Path.join(temporary, "cases")
	Path.copy_dir!("tests/cases", cases)?
	if Files.direct_roc_files!(cases)?.is_empty() {
		Err(NoTestCases)
	} else {
		Ok(cases)
	}
}

test_case_against_bundle! = |case, cases, url, roc_nightly, listener, bundle_bytes| {
	source = Path.read_utf8!(case)?
	Path.write_utf8!(case, UpdatePins.rewrite_source(source, url)?)?
	filename = Path.filename(case).map_ok(Path.display).map_err(|_| InvalidCasePath(Path.display(case)))?
	Script.info!("TEST", filename)?
	child = roc_nightly
		.cmd([OsStr.from_str(filename), "--no-cache"])
		.cwd(cases)
		.stdout(Capture)
		.stderr(Capture)
		.spawn!()
		.map_err(|err| SpawnFailed(err))?
	# The Roc child fetches the rewritten dependency while it compiles. This process
	# must service that request and wait for compilation at the same time.
	output = serve_bundle_until_exit!(child, listener, bundle_bytes)?
	match output.status {
		Exited(0) => {}
		Exited(code) => {
			Stderr.write_bytes!(output.stderr_bytes)?
			return Err(CaseExited(filename, code))
		}
		Signaled(signal) => return Err(CaseSignaled(filename, signal))
	}
	name = Files.stem(filename)
	expected : Path
	expected = "tests/goldens/${name}.json"
	if Path.read_bytes!(expected)? != output.stdout_bytes {
		return Err(GoldenMismatch(filename))
	}
	_ = Script.run_capture!(Cmd.new("pandoc"), ["--from=json", "--to=json"], cases, output.stdout_bytes)?
	Ok({})
}

serve_bundle_until_exit! = |child, listener, bundle_bytes| {
	# Poll briefly so we can alternate between checking the child and accepting its
	# package request without introducing threads or a long blocking accept.
	match child.try_wait!().map_err(|err| WaitFailed(err))? {
		[output] => Ok(output)
		[_, _, ..] => Err(UnexpectedWaitResult)
		[] =>
			match listener.accept!(100) {
				Ok(stream) => {
					_ = stream.read_until!(10, 65_536, 5_000)?
					stream.write_utf8!(http_ok_headers(bundle_bytes.len()), 5_000)?
					stream.write!(bundle_bytes, 30_000)?
					serve_bundle_until_exit!(child, listener, bundle_bytes)
				}
				Err(TcpListenErr(TimedOut)) => serve_bundle_until_exit!(child, listener, bundle_bytes)
				Err(err) => Err(ServeFailed(err))
			}
		}
}

http_ok_headers = |content_length|
# HTTP requires CRLF separators. A Roc multiline string would insert ordinary
# line feeds, so keep the readable line structure and join it explicitly.
	Str.join_with(
		[
			"HTTP/1.1 200 OK",
			"Content-Type: application/octet-stream",
			"Content-Length: ${content_length.to_str()}",
			"Connection: close",
			"",
			"",
		],
		"\r\n",
	)
