## Package a small EPUB 3 ebook with metadata and an automatically generated contents page:
## cd examples/ebook && roc main.roc
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	pandoc: "https://github.com/lukewilliamboswell/roc-pandoc/releases/download/0.1.0/8pDy8BV37fo72fRdpLr6rsAcosdJKJgVR2mT9GU17FuD.tar.zst",
	roc: "nightly-2026-09-18-1d982dc",
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
		|> Dict.insert("title", Pandoc.MetaValue.String("Field Notes from the Great Ocean Road"))
		|> Dict.insert("author", Pandoc.MetaValue.String("A. Traveller"))
		|> Dict.insert("lang", Pandoc.MetaValue.String("en-AU"))
		|> Dict.insert("rights", Pandoc.MetaValue.String("CC BY 4.0"))
	document = Author.document([
		Author.heading(1, "The road west"),
		Author.paragraph("Rain followed us past Anglesea, turning every fern glossy and every lookout silver."),
		Author.heading(2, "Packing notes"),
		Author.bullet_list([
			[Author.paragraph("A waterproof notebook")],
			[Author.paragraph("More drinking water than expected")],
			[Author.paragraph("Binoculars for the headlands")],
		]),
		Author.heading(1, "At Cape Otway"),
		Author.paragraph("The forest closed over the road before opening suddenly onto wind and ocean."),
	])
		|> Author.with_meta(meta)
	render!("field-notes.epub", Json.to_str(document), ["--to=epub3", "--toc"])
}
