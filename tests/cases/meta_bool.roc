app [main!] { pandoc: "../../package/main.roc" }

import pandoc.Pandoc

main! = |_args| {
	meta = Dict.empty()
		|> Dict.insert("isCool", Pandoc.MetaValue.Bool(True))
		|> Dict.insert("isNotCool", Pandoc.MetaValue.Bool(False))
	echo!(Pandoc.Document.{ meta, blocks: [] }.to_json())
	Ok({})
}
