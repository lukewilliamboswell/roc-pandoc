app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-10-a670e34" }

import pandoc.Pandoc

main! = |_args| {
	first = Pandoc.Block.Header(1, Pandoc.Attr.{ identifier: "first", classes: [], attributes: [] }, [Pandoc.Inline.String("First")])
	second = Pandoc.Block.Header(2, Pandoc.Attr.{ identifier: "second", classes: [], attributes: [] }, [Pandoc.Inline.String("Second")])
	document = Pandoc.Document.{ meta: Dict.empty(), blocks: [first, second] }
	echo!(Json.to_str(document))
	Ok({})
}
