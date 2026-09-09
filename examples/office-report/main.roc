## Generate an editable Word report (use --reference-doc=brand.docx to apply a house style):
## cd examples/office-report && roc main.roc
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
		|> Dict.insert("title", Pandoc.MetaValue.String("Engineering quarterly report"))
		|> Dict.insert("author", Pandoc.MetaValue.String("Platform team"))
		|> Dict.insert("date", Pandoc.MetaValue.String("2026-09-09"))
	document = Author.document([
		Author.heading(1, "Executive summary"),
		Author.paragraph("The migration finished on schedule. Reliability improved and the next quarter will focus on developer experience."),
		Author.heading(1, "Outcomes"),
		Author.bullet_list([
			[Author.paragraph_inlines([Author.strong("Reliability: "), Author.text("99.95% successful requests")])],
			[Author.paragraph_inlines([Author.strong("Delivery: "), Author.text("14 customer-facing releases")])],
			[Author.paragraph_inlines([Author.strong("Efficiency: "), Author.text("18% lower compute cost")])],
		]),
		Author.heading(1, "Next quarter"),
		Author.ordered_list([
			[Author.paragraph("Shorten local feedback loops")],
			[Author.paragraph("Publish operational runbooks")],
			[Author.paragraph("Automate release evidence")],
		]),
	])
		|> Author.with_meta(meta)
	render!("quarterly-report.docx", Json.to_str(document), ["--to=docx"])
}
