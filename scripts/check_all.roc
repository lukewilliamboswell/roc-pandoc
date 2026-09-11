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
import src/Files
import src/Script

main! = |_args| {
	# Repository automation is pinned to a stable Roc so routine maintenance does
	# not break when nightly changes. The package and examples are checked with the
	# latest nightly so this repository still detects upcoming compiler changes.
	roc_stable = Script.roc_stable!()?
	roc_nightly = Script.roc_nightly!()?

	# Keep these phases in execution order: tooling first, then everything that
	# exercises roc-pandoc with the development compiler.
	check_script_tooling!(roc_stable)?
	test_goldens!(roc_stable)?
	check_package!(roc_nightly)?
	check_example_apps!(roc_nightly)?
	test_generated_artifacts!(roc_nightly)?
	check_documentation!(roc_nightly)?
	Script.command("git").run!(["diff", "--check"])
}

check_script_tooling! = |roc_stable| {
	# These tests cover the pure planning logic used by the release scripts.
	roc_stable.run!(["test", "scripts/src/UpdatePins.roc"])?
	roc_stable.run!(["fmt", "--check", "scripts"])
}

test_goldens! = |roc_stable| {
	# The driver itself uses stable Roc; it obtains ROC_NIGHTLY from the environment
	# and uses that compiler for every golden test application.
	roc_stable.run!(["scripts/test_goldens.roc", "--", "--require-pandoc"])
}

check_package! = |roc_nightly| {
	roc_nightly.run!(["fmt", "--check", "package", "examples", "tests/cases"])?
	roc_nightly.run!(["check", "package/main.roc", "--no-cache"])
}

check_example_apps! = |roc_nightly| {
	examples = Files.app_roots!("examples")?
	for example in examples {
		roc_nightly.run!(["check", Path.to_os_str(example), "--no-cache"])?
		Script.pass!(Path.display(example))?
	}
	Ok({})
}

test_generated_artifacts! = |roc_nightly|
	Env.with_temp_dir!(
		|temporary| {
			# The larger examples write EPUB, DOCX, HTML, PPTX, and LaTeX files beside
			# their app roots. Run them in a copy so checks never modify the working tree.
			Path.copy_dir!("package", Path.join(temporary, "package"))?
			Path.copy_dir!("examples", Path.join(temporary, "examples"))?
			for (workflow, output_name, kind) in generated_examples {
				workdir = Path.join(Path.join(temporary, "examples"), workflow)
				_ = roc_nightly.capture!(["main.roc", "--no-cache"], workdir, [])?
				artifact = Path.join(workdir, output_name)
				validate_artifact!(artifact, kind)?
				json_path = Path.join(workdir, "${output_name}.pandoc.json")
				# Decode only the field this check needs. Roc's structural JSON decoder
				# safely skips the detailed Pandoc block representation and other fields.
				document : { blocks : List({}) }
				document = Json.parse(Path.read_utf8!(json_path)?).map_err(|err| InvalidPandocJson(Path.display(json_path), err))?
				if document.blocks.is_empty() {
					return Err(NoPandocBlocks(Path.display(json_path)))
				}
				Script.pass!("examples/${workflow}/${output_name}")?
			}
			Ok({})
		},
	)

check_documentation! = |roc_nightly|
	Env.with_temp_dir!(|output| roc_nightly.run!(["docs", "package/main.roc", "--output=${Path.display(output)}", "--no-cache"]))

generated_examples = [
	("ebook", "field-notes.epub", Zip),
	("office-report", "quarterly-report.docx", Zip),
	("research-summary", "research.html", Html("Functional build design: research summary")),
	("slide-deck", "demo-day.pptx", Zip),
	("technical-paper", "paper.tex", Latex),
	("web-page", "product.html", Html("Acorn task manager")),
]

validate_artifact! = |path, kind| {
	Script.require_file!(path)?
	if Path.size_in_bytes!(path)? == 0 {
		return Err(EmptyArtifact(Path.display(path)))
	}
	match kind {
		Zip => {
			match Env.platform!().os {
				LINUX | MACOS => {}
				WINDOWS | OTHER(_) => return Err(ZipValidationRequiresUnix)
			}
			if !Cmd.check_available!("unzip") {
				return Err(UnzipUnavailable)
			}
			Script.command("unzip").run!(["-tqq", Path.to_os_str(path)])
		}
		Html(title) => {
			content = Path.read_utf8!(path)?
			if content.contains("<title>${title}</title>") Ok({}) else Err(UnexpectedHtmlTitle(Path.display(path)))
		}
		Latex => {
			content = Path.read_utf8!(path)?
			if content.contains("\\begin{document}") and content.contains("\\end{document}") Ok({}) else Err(InvalidLatex(Path.display(path)))
		}
	}
}
