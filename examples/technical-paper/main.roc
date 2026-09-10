## Produce LaTeX, or replace the final arguments with `--pdf-engine=xelatex -o paper.pdf` for PDF:
## cd examples/technical-paper && roc main.roc
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	pandoc: "https://github.com/lukewilliamboswell/roc-pandoc/releases/download/0.1.0/8pDy8BV37fo72fRdpLr6rsAcosdJKJgVR2mT9GU17FuD.tar.zst",
	roc: "nightly-2026-09-10-a670e34",
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
		|> Dict.insert("title", Pandoc.MetaValue.String("Predictable build latency"))
		|> Dict.insert("author", Pandoc.MetaValue.String("Example Research Group"))
	document = Author.document([
		Author.heading(1, "Model"),
		Author.paragraph_inlines([
			Author.text("We approximate elapsed build time with "),
			Pandoc.Inline.Math(Pandoc.MathType.InlineMath, "T(n) = \\alpha n + \\beta"),
			Author.text(" and fit the constants from clean builds."),
		]),
		Pandoc.Block.CodeBlock(
			Pandoc.Attr.{ identifier: "fit", classes: ["roc"], attributes: [("caption", "A tiny linear predictor")] },
			"estimate = |files, alpha, beta| alpha * files + beta",
		),
		Author.heading(1, "Interpretation"),
		Author.block_quote([Author.paragraph("Variance matters more than the fastest observed build.")]),
	])
		|> Author.with_meta(meta)
	render!("paper.tex", Json.to_str(document), ["--to=latex", "--standalone"])
}
