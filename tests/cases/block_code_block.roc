app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-10-01-a932c65" }

import pandoc.Pandoc

main! = |_args| {
	document = Pandoc.Document.{
		meta: Dict.empty(),
		blocks: [Pandoc.Block.CodeBlock(Pandoc.Attr.empty, "x = 1;")],
	}
	echo!(Json.to_str(document))
	Ok({})
}
