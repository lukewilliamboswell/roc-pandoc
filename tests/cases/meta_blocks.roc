app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-17-9221bca" }

import pandoc.Pandoc

main! = |_args| {
	abstract = Pandoc.MetaValue.Blocks([
		Pandoc.Block.Para([Pandoc.Inline.String("Para"), Pandoc.Inline.Space, Pandoc.Inline.String("1")]),
		Pandoc.Block.Para([Pandoc.Inline.String("Para"), Pandoc.Inline.Space, Pandoc.Inline.String("2")]),
	])
	meta = Dict.empty() |> Dict.insert("abstract", abstract)
	echo!(Json.to_str(Pandoc.Document.{ meta, blocks: [] }))
	Ok({})
}
