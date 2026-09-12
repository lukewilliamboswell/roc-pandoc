app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-12-220fd47" }

import pandoc.Pandoc

main! = |_args| {
	text = [Pandoc.Inline.String("content")]
	plain = Pandoc.Block.Plain(text)
	caption = Pandoc.Caption.{ short: None, long: [plain] }
	definition = Pandoc.Definition.{ term: [Pandoc.Inline.String("term")], definitions: [[plain]] }
	document = Pandoc.Document.{
		meta: Dict.empty(),
		blocks: [
			Pandoc.Block.RawBlock("html", "<b>raw</b>"),
			Pandoc.Block.BlockQuote([Pandoc.Block.Para(text)]),
			Pandoc.Block.BulletList([[plain], [plain]]),
			Pandoc.Block.DefinitionList([definition]),
			Pandoc.Block.HorizontalRule,
			Pandoc.Block.Figure(Pandoc.Attr.empty, caption, [plain]),
			Pandoc.Block.Div(Pandoc.Attr.{ identifier: "section", classes: [], attributes: [] }, [plain]),
		],
	}
	echo!(Json.to_str(document))
	Ok({})
}
