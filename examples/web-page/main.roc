## Build a standalone HTML product page:
## cd examples/web-page && roc main.roc
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	pandoc: "https://github.com/lukewilliamboswell/roc-pandoc/releases/download/0.1.0/8pDy8BV37fo72fRdpLr6rsAcosdJKJgVR2mT9GU17FuD.tar.zst",
	roc: "nightly-2026-09-15-fe09c42",
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
		|> Dict.insert("title", Pandoc.MetaValue.String("Acorn task manager"))
	document = Author.document([
		Author.heading(1, "Acorn task manager"),
		Author.paragraph_inlines([
			Author.text("A small, fast task manager written in "),
			Author.link("Roc", "https://roc-lang.org"),
			Author.text("."),
		]),
		Author.heading(2, "Why teams use it"),
		Author.bullet_list([
			[Author.paragraph("One plain-text file per project")],
			[Author.paragraph("Useful HTML exports for sharing")],
			[Author.paragraph("No account or network connection required")],
		]),
		Author.block_quote([Author.paragraph("The boring workflow is the reliable workflow.")]),
	])
		|> Author.with_meta(meta)
	render!("product.html", Json.to_str(document), ["--to=html5", "--standalone"])
}
