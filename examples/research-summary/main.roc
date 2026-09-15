## Render citations and a comparison table using a CSL bibliography:
## cd examples/research-summary && roc main.roc
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

cell : Str -> Pandoc.Cell
cell = |value| Pandoc.Cell.{
	attr: Pandoc.Attr.empty,
	alignment: Pandoc.Alignment.Left,
	row_span: 1,
	col_span: 1,
	blocks: [Pandoc.Block.Plain([Author.text(value)])],
}

row : List(Str) -> Pandoc.Row
row = |values| Pandoc.Row.{ attr: Pandoc.Attr.empty, cells: values.map(cell) }

main! = |_args| {
	meta = Dict.empty()
		|> Dict.insert("title", Pandoc.MetaValue.String("Functional build design: research summary"))
	citation = Pandoc.Citation.{
		id: "wadler1992",
		prefix: [],
		suffix: [],
		mode: Pandoc.CitationMode.NormalCitation,
		note_num: 0,
		hash: 0,
	}
	table = Pandoc.Block.Table(
		Pandoc.Attr.empty,
		Pandoc.Caption.{ short: None, long: [Author.paragraph("Observed build results")] },
		[
			Pandoc.ColSpec.{ alignment: Pandoc.Alignment.Left, width: Pandoc.ColWidth.Default },
			Pandoc.ColSpec.{ alignment: Pandoc.Alignment.Right, width: Pandoc.ColWidth.Default },
			Pandoc.ColSpec.{ alignment: Pandoc.Alignment.Right, width: Pandoc.ColWidth.Default },
		],
		Pandoc.TableHead.{ attr: Pandoc.Attr.empty, rows: [row(["Variant", "Median", "p95"])] },
		[
			Pandoc.TableBody.{
				attr: Pandoc.Attr.empty,
				row_head_columns: 1,
				intermediate_head: [],
				body: [
					row(["Baseline", "42 s", "71 s"]),
					row(["Cached", "11 s", "16 s"]),
				],
			},
		],
		Pandoc.TableFoot.{ attr: Pandoc.Attr.empty, rows: [] },
	)
	document = Author.document([
		Author.heading(1, "Research summary"),
		Author.paragraph_inlines([
			Author.text("The design follows the separation of pure and effectful code described by "),
			Pandoc.Inline.Cite([citation], [Author.text("Wadler")]),
			Author.text("."),
		]),
		table,
	])
		|> Author.with_meta(meta)
	render!("research.html", Json.to_str(document), ["--citeproc", "--bibliography=references.bib", "--to=html5", "--standalone"])
}
