app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-11-793f9d8" }

import pandoc.Pandoc

main! = |_args| {
	document = Pandoc.Document.{
		meta: Dict.empty(),
		blocks: [Pandoc.Block.Para([Pandoc.Inline.String("foo")])],
	}
	echo!(Json.to_str(document))
	Ok({})
}
