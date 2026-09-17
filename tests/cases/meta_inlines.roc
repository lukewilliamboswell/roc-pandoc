app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-17-9221bca" }

import pandoc.Pandoc

main! = |_args| {
	title = Pandoc.MetaValue.Inlines([Pandoc.Inline.String("Foo"), Pandoc.Inline.Space, Pandoc.Inline.Emph([Pandoc.Inline.String("bar")])])
	meta = Dict.empty() |> Dict.insert("title", title)
	echo!(Json.to_str(Pandoc.Document.{ meta, blocks: [] }))
	Ok({})
}
