app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-11-793f9d8" }

import pandoc.Pandoc

main! = |_args| {
	nested = Dict.empty()
		|> Dict.insert("plain", Pandoc.MetaValue.String("quotes: \" and slash: \\"))
		|> Dict.insert("nested-key", Pandoc.MetaValue.Bool(True))
	meta = Dict.empty() |> Dict.insert("map\"key", Pandoc.MetaValue.Map(nested))
	echo!(Json.to_str(Pandoc.Document.{ meta, blocks: [] }))
	Ok({})
}
