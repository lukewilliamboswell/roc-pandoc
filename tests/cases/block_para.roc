app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-27-a3ce7f1" }

import pandoc.Pandoc

main! = |_args| {
	document = Pandoc.Document.{
		meta: Dict.empty(),
		blocks: [Pandoc.Block.Para([Pandoc.Inline.String("foo")])],
	}
	echo!(Json.to_str(document))
	Ok({})
}
