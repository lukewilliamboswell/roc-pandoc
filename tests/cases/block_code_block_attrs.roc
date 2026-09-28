app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-27-a3ce7f1" }

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
