app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	roc: "nightly-2026-09-08-39a3f89",
	pandoc: "../package/main.roc",
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
