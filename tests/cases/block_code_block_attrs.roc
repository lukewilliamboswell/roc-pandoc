app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-08-39a3f89" }

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
	echo!(document.to_json())
	Ok({})
}
