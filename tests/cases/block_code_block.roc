app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-15-fe09c42" }

import pandoc.Pandoc

main! = |_args| {
	document = Pandoc.Document.{
		meta: Dict.empty(),
		blocks: [Pandoc.Block.CodeBlock(Pandoc.Attr.empty, "x = 1;")],
	}
	echo!(Json.to_str(document))
	Ok({})
}
