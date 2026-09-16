app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-16-a49a16f" }

import pandoc.Pandoc

main! = |_args| {
	document = Pandoc.Document.{
		meta: Dict.empty(),
		blocks: [Pandoc.Block.LineBlock([[Pandoc.Inline.String("foo")], [Pandoc.Inline.String("bar")]])],
	}
	echo!(Json.to_str(document))
	Ok({})
}
