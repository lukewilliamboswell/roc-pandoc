app [main!] { pandoc: "../../package/main.roc" }

import pandoc.Pandoc

main! = |_args| {
	document = Pandoc.Document.{
		meta: Dict.empty(),
		blocks: [Pandoc.Block.Para([Pandoc.Inline.String("foo")])],
	}
	echo!(document.to_json())
	Ok({})
}
