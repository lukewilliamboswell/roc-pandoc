app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-09-7dadc35" }

import pandoc.Pandoc

main! = |_args| {
	cell = Pandoc.Cell.{ attr: Pandoc.Attr.empty, alignment: Pandoc.Alignment.Default, row_span: 1, col_span: 1, blocks: [Pandoc.Block.Plain([Pandoc.Inline.String("cell")])] }
	row = Pandoc.Row.{ attr: Pandoc.Attr.empty, cells: [cell] }
	table = Pandoc.Block.Table(
		Pandoc.Attr.empty,
		Pandoc.Caption.{ short: Some([Pandoc.Inline.String("short")]), long: [Pandoc.Block.Plain([Pandoc.Inline.String("caption")])] },
		[Pandoc.ColSpec.{ alignment: Pandoc.Alignment.Left, width: Pandoc.ColWidth.Fraction(1.0) }],
		Pandoc.TableHead.{ attr: Pandoc.Attr.empty, rows: [row] },
		[Pandoc.TableBody.{ attr: Pandoc.Attr.empty, row_head_columns: 0, intermediate_head: [], body: [row] }],
		Pandoc.TableFoot.{ attr: Pandoc.Attr.empty, rows: [] },
	)
	echo!(Json.to_str(Pandoc.Document.{ meta: Dict.empty(), blocks: [table] }))
	Ok({})
}
