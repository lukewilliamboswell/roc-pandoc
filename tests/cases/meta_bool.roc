app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-08-39a3f89" }

import pandoc.Pandoc

main! = |_args| {
	meta = Dict.empty()
		|> Dict.insert("isCool", Pandoc.MetaValue.Bool(True))
		|> Dict.insert("isNotCool", Pandoc.MetaValue.Bool(False))
	echo!(Pandoc.Document.{ meta, blocks: [] }.to_json())
	Ok({})
}
