app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	pandoc: "https://github.com/lukewilliamboswell/roc-pandoc/releases/download/0.1.0/8pDy8BV37fo72fRdpLr6rsAcosdJKJgVR2mT9GU17FuD.tar.zst",
	parser: "https://github.com/lukewilliamboswell/roc-parser/releases/download/1.2.0/GzeZxk7V7GHFa42qhgzd8gUgX6cEyY3NmrwmDfsuskNd.tar.zst",
	roc: "nightly-2026-09-08-39a3f89",
}

import pandoc.Pandoc
import parser.Markdown
import parser.String
import cli.OsStr
import Render

source =
	\\# September release notes
	\\
	\\The **new compiler** is *fast* and ~~experimental~~ ready to try.
	\\
	\\## Highlights
	\\
	\\1. Static dispatch
	\\2. Nominal types

main! : List(OsStr) => Try({}, _)
main! = |args| {
	markdown_input = args.get(1).map_ok(OsStr.display) ?? source
	document =
		match String.parse_str(Markdown.all, markdown_input) {
			Ok(nodes) => Pandoc.Document.{
				meta: Dict.empty() |> Dict.insert("title", Pandoc.MetaValue.String("Roc release notes")),
				blocks: nodes.map(markdown_block),
			}
			Err(_) => Pandoc.Document.{
				meta: Dict.empty(),
				blocks: [Pandoc.Block.Para([Pandoc.Inline.String("Could not parse the Markdown input.")])],
			}
		}

	Render.html_and_open!("roc-release-notes", Json.to_str(document))?
	Ok({})
}

markdown_block : Markdown.Markdown -> Pandoc.Block
markdown_block = |node| match node {
	Heading({ level, content }) => Pandoc.Block.Header(heading_level(level), Pandoc.Attr.empty, content.map(markdown_inline))
	Paragraph(content) => Pandoc.Block.Para(content.map(markdown_inline))
	Code({ info, pre }) => Pandoc.Block.CodeBlock(Pandoc.Attr.{ identifier: "", classes: [info], attributes: [] }, pre)
	Blockquote(children) => Pandoc.Block.Para([Pandoc.Inline.String("Quote: ")].concat(children.map(block_text).join()))
	ListBlock({ kind, items, .. }) =>
		match kind {
			Ordered({ start }) => Pandoc.Block.OrderedList(
				Pandoc.ListAttributes.{ start: I32.from_str(start.to_str()) ?? 1, style: Pandoc.ListStyle.Decimal, delimiter: Pandoc.ListDelimiter.Period },
				items.map(|item| item.blocks.map(markdown_block)),
			)
			Unordered => Pandoc.Block.Para([Pandoc.Inline.String("List: ")].concat(items.map(|item| item.blocks.map(block_text).join()).join()))
		}
	Table(_) => Pandoc.Block.Para([Pandoc.Inline.String("[table]")])
	ThematicBreak => Pandoc.Block.Plain([Pandoc.Inline.String("---")])
	HtmlBlock(raw) => Pandoc.Block.CodeBlock(Pandoc.Attr.{ identifier: "", classes: ["html"], attributes: [] }, raw)
	Frontmatter({ raw }) => Pandoc.Block.CodeBlock(Pandoc.Attr.{ identifier: "", classes: ["yaml"], attributes: [] }, raw)
	TODO(line) => Pandoc.Block.Para([Pandoc.Inline.String(line)])
}

block_text : Markdown.Markdown -> List(Pandoc.Inline)
block_text = |node| match node {
	Paragraph(content) => content.map(markdown_inline)
	Heading({ content, .. }) => content.map(markdown_inline)
	_ => []
}

markdown_inline : Markdown.Inline -> Pandoc.Inline
markdown_inline = |inline| match inline {
	Text(text) => Pandoc.Inline.String(text)
	Strong(children) => Pandoc.Inline.Strong(children.map(markdown_inline))
	Emphasis(children) => Pandoc.Inline.Emph(children.map(markdown_inline))
	Strikethrough(children) => Pandoc.Inline.Strikeout(children.map(markdown_inline))
	InlineCode(code) => Pandoc.Inline.String(code)
	Link({ label, .. }) => Pandoc.Inline.Underline(label.map(markdown_inline))
	Image({ alt, .. }) => Pandoc.Inline.SmallCaps(alt.map(markdown_inline))
	HardBreak => Pandoc.Inline.LineBreak
	HtmlInline(raw) => Pandoc.Inline.String(raw)
}

heading_level : Markdown.Level -> I32
heading_level = |level| match level {
	One => 1
	Two => 2
	Three => 3
	Four => 4
	Five => 5
	Six => 6
}
