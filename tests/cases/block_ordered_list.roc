app [main!] { pandoc: "../../package/main.roc" }

import pandoc.Pandoc

main! = |_args| {
	attributes = Pandoc.ListAttributes.{ start: 1, style: Pandoc.ListStyle.Decimal, delimiter: Pandoc.ListDelimiter.Period }
	items = [
		[Pandoc.Block.Plain([Pandoc.Inline.String("one")])],
		[Pandoc.Block.Plain([Pandoc.Inline.String("two")])],
		[Pandoc.Block.Plain([Pandoc.Inline.String("three")])],
	]
	document = Pandoc.Document.{ meta: Dict.empty(), blocks: [Pandoc.Block.OrderedList(attributes, items)] }
	echo!(document.to_json())
	Ok({})
}
