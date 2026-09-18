app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-18-1d982dc" }

import pandoc.Pandoc

main! = |_args| {
	text = [Pandoc.Inline.String("text")]
	citation = Pandoc.Citation.{ id: "doe", prefix: [], suffix: [], mode: Pandoc.CitationMode.NormalCitation, note_num: 0, hash: 0 }
	inlines = [
		Pandoc.Inline.Quoted(Pandoc.QuoteType.DoubleQuote, text),
		Pandoc.Inline.Cite([citation], text),
		Pandoc.Inline.Code(Pandoc.Attr.empty, "x = 1"),
		Pandoc.Inline.Math(Pandoc.MathType.InlineMath, "x^2"),
		Pandoc.Inline.RawInline("html", "<mark>x</mark>"),
		Pandoc.Inline.Link(Pandoc.Attr.empty, text, Pandoc.Target.{ url: "https://example.com", title: "Example" }),
		Pandoc.Inline.Image(Pandoc.Attr.empty, text, Pandoc.Target.{ url: "image.png", title: "Image" }),
		Pandoc.Inline.Note([Pandoc.Block.Para(text)]),
		Pandoc.Inline.Span(Pandoc.Attr.{ identifier: "mark", classes: ["highlight"], attributes: [] }, text),
	]
	echo!(Json.to_str(Pandoc.Document.{ meta: Dict.empty(), blocks: [Pandoc.Block.Para(inlines)] }))
	Ok({})
}
