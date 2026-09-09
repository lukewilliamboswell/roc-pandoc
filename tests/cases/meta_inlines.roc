app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-08-39a3f89" }

import pandoc.Pandoc

main! = |_args| {
	title = Pandoc.MetaValue.Inlines([Pandoc.Inline.String("Foo"), Pandoc.Inline.Space, Pandoc.Inline.Emph([Pandoc.Inline.String("bar")])])
	meta = Dict.empty() |> Dict.insert("title", title)
	echo!(Pandoc.Document.{ meta, blocks: [] }.to_json())
	Ok({})
}
