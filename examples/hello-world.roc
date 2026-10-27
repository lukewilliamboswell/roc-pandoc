app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
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
