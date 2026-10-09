app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.24.0/AEjfyaMFFbh8FJrkkHJy68riVNPr3Qp6c6PawWQjBwMH.tar.zst",
	pandoc: "https://github.com/lukewilliamboswell/roc-pandoc/releases/download/0.1.0/8pDy8BV37fo72fRdpLr6rsAcosdJKJgVR2mT9GU17FuD.tar.zst",
	roc: "nightly-2026-10-09-258ab27",
}

import cli.Stdout
import pandoc.Pandoc

main! = |_args| {
	document = Pandoc.Document.{
		meta: Dict.empty() |> Dict.insert("isBasic", Pandoc.MetaValue.Bool(True)),
		blocks: [
			Pandoc.Block.Header(1, Pandoc.Attr.{ identifier: "first", classes: [], attributes: [] }, [Pandoc.Inline.String("Hello")]),
			Pandoc.Block.Para([Pandoc.Inline.String("world")]),
		],
	}
	Stdout.line!(Json.to_str(document))
}
