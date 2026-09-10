app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-09-7dadc35" }

import pandoc.Pandoc

main! = |_args| {
	authors = Pandoc.MetaValue.List([
		Pandoc.MetaValue.Inlines([Pandoc.Inline.String("BAR")]),
		Pandoc.MetaValue.Inlines([Pandoc.Inline.String("BAZ")]),
	])
	meta = Dict.empty() |> Dict.insert("author", authors)
	echo!(Json.to_str(Pandoc.Document.{ meta, blocks: [] }))
	Ok({})
}
