app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-08-39a3f89" }

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
