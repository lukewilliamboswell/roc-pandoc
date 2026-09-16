app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-16-a49a16f" }

import pandoc.Pandoc

main! = |_args| {
	title = Pandoc.MetaValue.Inlines([Pandoc.Inline.String("Foo"), Pandoc.Inline.Space, Pandoc.Inline.Emph([Pandoc.Inline.String("bar")])])
	meta = Dict.empty() |> Dict.insert("title", title)
	echo!(Json.to_str(Pandoc.Document.{ meta, blocks: [] }))
	Ok({})
}
