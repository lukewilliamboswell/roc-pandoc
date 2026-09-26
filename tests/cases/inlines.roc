app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-26-d6267b4" }

import pandoc.Pandoc

main! = |_args| {
	blocks = [
		Pandoc.Block.Para([Pandoc.Inline.String("text"), Pandoc.Inline.SoftBreak, Pandoc.Inline.Emph([Pandoc.Inline.String("emphasized")])]),
		Pandoc.Block.Para([Pandoc.Inline.Underline([Pandoc.Inline.String("underlined")]), Pandoc.Inline.SoftBreak, Pandoc.Inline.Strong([Pandoc.Inline.String("strong")])]),
		Pandoc.Block.Para([Pandoc.Inline.Strikeout([Pandoc.Inline.String("strikeout")]), Pandoc.Inline.SoftBreak, Pandoc.Inline.Superscript([Pandoc.Inline.String("superscripted")])]),
		Pandoc.Block.Para([Pandoc.Inline.Subscript([Pandoc.Inline.String("subscripted")]), Pandoc.Inline.SoftBreak, Pandoc.Inline.SmallCaps([Pandoc.Inline.String("smallcaps")])]),
	]
	document = Pandoc.Document.{ meta: Dict.empty(), blocks }
	echo!(Json.to_str(document))
	Ok({})
}
