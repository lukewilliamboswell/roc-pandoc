## Create an editable PowerPoint deck; level-one headings begin new slides:
## roc examples/slide-deck/main.roc
## Swap `--to=pptx` for `--to=revealjs --standalone` to publish the same deck on the web.
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	pandoc: "../../package/main.roc",
	roc: "nightly-2026-09-08-39a3f89",
}

import cli.Cmd
import cli.OsStr
import cli.Path
import cli.Stderr
import cli.Stdout
import pandoc.Author
import pandoc.Pandoc

render! : Str, Str, List(Str) => Try({}, _)
render! = |output_path, json, options| {
	if !Cmd.check_available!("pandoc") {
		Stderr.line!("Could not find pandoc on PATH.")?
		return Err(Exit(1))
	}
	input_path : Path
	input_path = "${output_path}.pandoc.json"
	input_path.write_utf8!(json)?
	args = ["--from=json", "--output=${output_path}"].concat(options).append(input_path.display()).map(OsStr.from_str)
	Cmd.exec!("pandoc", args)?
	Stdout.line!("Generated ${output_path}")?
	Ok({})
}

main! = |_args| {
	meta = Dict.empty()
		|> Dict.insert("title", Pandoc.MetaValue.String("A calmer release process"))
		|> Dict.insert("subtitle", Pandoc.MetaValue.String("Demo day"))
		|> Dict.insert("author", Pandoc.MetaValue.String("Release engineering"))
	document = Author.document([
		Author.heading(1, "The problem"),
		Author.bullet_list([
			[Author.paragraph("Release knowledge lived in chat")],
			[Author.paragraph("Manual checks were easy to skip")],
			[Author.paragraph("Rollback decisions arrived too late")],
		]),
		Author.heading(1, "The workflow"),
		Author.ordered_list([
			[Author.paragraph("Build one immutable candidate")],
			[Author.paragraph("Collect automated evidence")],
			[Author.paragraph("Promote or roll back")],
		]),
		Author.heading(1, "Result"),
		Author.paragraph_inlines([Author.strong("30 minutes"), Author.text(" from merge to a verified production release.")]),
	])
		|> Author.with_meta(meta)
	render!("examples/slide-deck/demo-day.pptx", document.to_json(), ["--to=pptx", "--slide-level=1"])
}
