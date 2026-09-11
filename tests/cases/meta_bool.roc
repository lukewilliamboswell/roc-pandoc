app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-11-793f9d8" }

import pandoc.Pandoc

main! = |_args| {
	meta = Dict.empty()
		|> Dict.insert("isCool", Pandoc.MetaValue.Bool(True))
		|> Dict.insert("isNotCool", Pandoc.MetaValue.Bool(False))
	echo!(Json.to_str(Pandoc.Document.{ meta, blocks: [] }))
	Ok({})
}
