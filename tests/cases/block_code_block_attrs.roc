app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-26-d6267b4" }

import pandoc.Pandoc

main! = |_args| {
	attributes = Pandoc.Attr.{
		identifier: "code",
		classes: ["foolang", "haskell", "numberLines"],
		attributes: [("startFrom", "100")],
	}
	document = Pandoc.Document.{
		meta: Dict.empty(),
		blocks: [Pandoc.Block.CodeBlock(attributes, "bar")],
	}
	echo!(Json.to_str(document))
	Ok({})
}
