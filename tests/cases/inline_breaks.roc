app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-18-1d982dc" }

import pandoc.Pandoc

main! = |_args| {
	document = Pandoc.Document.{
		meta: Dict.empty(),
		blocks: [
			Pandoc.Block.Para([
				Pandoc.Inline.String("first"),
				Pandoc.Inline.Space,
				Pandoc.Inline.String("line"),
				Pandoc.Inline.LineBreak,
				Pandoc.Inline.String("second"),
				Pandoc.Inline.SoftBreak,
				Pandoc.Inline.String("third"),
			]),
		],
	}
	echo!(Json.to_str(document))
	Ok({})
}
