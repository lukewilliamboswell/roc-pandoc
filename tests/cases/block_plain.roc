app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-09-7dadc35" }

import pandoc.Pandoc

main! = |_args| {
	document = Pandoc.Document.{
		meta: Dict.empty(),
		blocks: [Pandoc.Block.Plain([Pandoc.Inline.String("plain"), Pandoc.Inline.Space, Pandoc.Inline.String("text")])],
	}
	echo!(Json.to_str(document))
	Ok({})
}
