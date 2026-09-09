app [main!] { pandoc: "../../package/main.roc" }

import pandoc.Pandoc

main! = |_args| {
	authors = Pandoc.MetaValue.List([
		Pandoc.MetaValue.Inlines([Pandoc.Inline.String("BAR")]),
		Pandoc.MetaValue.Inlines([Pandoc.Inline.String("BAZ")]),
	])
	meta = Dict.empty() |> Dict.insert("author", authors)
	echo!(Pandoc.Document.{ meta, blocks: [] }.to_json())
	Ok({})
}
