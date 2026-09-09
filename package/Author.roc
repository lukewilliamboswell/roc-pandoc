## Ergonomic constructors for common document-authoring tasks.
##
## `Author` is the concise API for ordinary prose. Every helper returns an exact
## type from `Pandoc`, so these values can be freely mixed with advanced
## constructors for metadata, attributes, tables, citations, figures, raw
## content, and other precise document structure.
import Pandoc

Author := [].{

	## Create a document with empty metadata from a list of blocks.
	##
	## ```roc
	## doc = Author.document([
	##     Author.heading(1, "Notes"),
	##     Author.paragraph("A short document."),
	## ])
	## ```
	##
	## Use `with_meta` when the output format needs a title, author, language, or
	## other document metadata.
	document : List(Pandoc.Block) -> Pandoc.Document
	document = |blocks| Pandoc.Document.{ meta: Dict.empty(), blocks }

	## Create a document with title metadata already attached.
	##
	## This is the common starting point for standalone HTML, office documents,
	## slide decks, and ebooks, whose writers expect a document title.
	titled_document : Str, List(Pandoc.Block) -> Pandoc.Document
	titled_document = |title, blocks| Pandoc.Document.{
		meta: Dict.empty() |> Dict.insert("title", Pandoc.MetaValue.String(title)),
		blocks,
	}

	## Replace all of a document's metadata while preserving its blocks.
	##
	## ```roc
	## titled = Author.document([Author.paragraph("Hello")])
	##     |> Author.with_meta(
	##         Dict.empty()
	##             |> Dict.insert("title", Pandoc.MetaValue.String("Greeting")),
	##     )
	## ```
	##
	## This replaces rather than merges the existing map. Build or update the
	## complete `Dict` before passing it here.
	with_meta : Pandoc.Document, Dict(Str, Pandoc.MetaValue) -> Pandoc.Document
	with_meta = |doc, meta| Pandoc.Document.{ meta, blocks: doc.blocks }

	## Create an inline string.
	##
	## Combine `text` with formatting helpers inside `paragraph_inlines` or
	## `heading_inlines`. Spaces are not inserted automatically.
	text : Str -> Pandoc.Inline
	text = |value| Pandoc.Inline.String(value)

	## Create a paragraph containing one unformatted inline string.
	##
	## Use `paragraph_inlines` when only part of the paragraph is formatted or
	## linked. Newlines in the string do not create separate Pandoc blocks.
	paragraph : Str -> Pandoc.Block
	paragraph = |value| Pandoc.Block.Para([text(value)])

	## Create a paragraph from pre-built inline content.
	##
	## ```roc
	## intro = Author.paragraph_inlines([
	##     Author.text("Built with "),
	##     Author.strong("Roc"),
	##     Author.text("."),
	## ])
	## ```
	##
	## The list is used exactly as provided; add text spaces or
	## `Pandoc.Inline.Space` explicitly where required.
	paragraph_inlines : List(Pandoc.Inline) -> Pandoc.Block
	paragraph_inlines = |inlines| Pandoc.Block.Para(inlines)

	## Create an unadorned heading from a level and plain text.
	##
	## The level is passed through without validation and the heading has no
	## identifier, classes, or attributes. Use `Pandoc.Block.Header` for those.
	heading : I32, Str -> Pandoc.Block
	heading = |level, value| Pandoc.Block.Header(level, Pandoc.Attr.empty, [text(value)])

	## Create a level-one heading without spelling its numeric level.
	h1 : Str -> Pandoc.Block
	h1 = |value| heading(1, value)

	## Create a level-two heading without spelling its numeric level.
	h2 : Str -> Pandoc.Block
	h2 = |value| heading(2, value)

	## Create a level-three heading without spelling its numeric level.
	h3 : Str -> Pandoc.Block
	h3 = |value| heading(3, value)

	## Create an unadorned heading from formatted inline content.
	##
	## ```roc
	## heading = Author.heading_inlines(2, [
	##     Author.text("An "),
	##     Author.emph("important"),
	##     Author.text(" section"),
	## ])
	## ```
	##
	## The level is not validated and attributes remain empty.
	heading_inlines : I32, List(Pandoc.Inline) -> Pandoc.Block
	heading_inlines = |level, inlines| Pandoc.Block.Header(level, Pandoc.Attr.empty, inlines)

	## Emphasize a plain string.
	##
	## Use `Pandoc.Inline.Emph` directly to emphasize multiple or nested inlines.
	emph : Str -> Pandoc.Inline
	emph = |value| Pandoc.Inline.Emph([text(value)])

	## Strongly emphasize a plain string.
	##
	## Use `Pandoc.Inline.Strong` directly for formatted or nested content.
	strong : Str -> Pandoc.Inline
	strong = |value| Pandoc.Inline.Strong([text(value)])

	## Create inline code with no identifier, classes, or attributes.
	##
	## Use `Pandoc.Inline.Code` to attach a language class or other attributes.
	code : Str -> Pandoc.Inline
	code = |value| Pandoc.Inline.Code(Pandoc.Attr.empty, value)

	## Create a code block with no identifier, classes, or attributes.
	##
	## Syntax highlighting usually requires the advanced constructor with a
	## language in `Pandoc.Attr.classes`.
	code_block : Str -> Pandoc.Block
	code_block = |value| Pandoc.Block.CodeBlock(Pandoc.Attr.empty, value)

	## Create a syntax-highlighted code block using a Pandoc language class.
	code_block_language : Str, Str -> Pandoc.Block
	code_block_language = |language, value| Pandoc.Block.CodeBlock(
		Pandoc.Attr.{ identifier: "", classes: [language], attributes: [] },
		value,
	)

	## Create a link with a plain-text label and no title or attributes.
	##
	## ```roc
	## project = Author.link("Roc", "https://roc-lang.org")
	## ```
	##
	## Use `Pandoc.Inline.Link` for formatted labels, link titles, identifiers,
	## classes, or key-value attributes.
	link : Str, Str -> Pandoc.Inline
	link = |label, url| Pandoc.Inline.Link(Pandoc.Attr.empty, [text(label)], Pandoc.Target.{ url, title: "" })

	## Create an image with a plain-text description and no title or attributes.
	##
	## The description becomes Pandoc's inline alternative text. Use
	## `Pandoc.Inline.Image` for formatted descriptions, titles, or attributes.
	image : Str, Str -> Pandoc.Inline
	image = |description, url| Pandoc.Inline.Image(Pandoc.Attr.empty, [text(description)], Pandoc.Target.{ url, title: "" })

	## Wrap one or more blocks in a block quotation.
	##
	## ```roc
	## quote = Author.block_quote([
	##     Author.paragraph("Make illegal states unrepresentable."),
	## ])
	## ```
	block_quote : List(Pandoc.Block) -> Pandoc.Block
	block_quote = |blocks| Pandoc.Block.BlockQuote(blocks)

	## Create a bullet list whose items may each contain multiple blocks.
	##
	## ```roc
	## list = Author.bullet_list([
	##     [Author.paragraph("First item")],
	##     [Author.paragraph("Second item")],
	## ])
	## ```
	##
	## The nested shape is significant: the outer list contains items and each
	## item contains blocks. Empty items are not rejected.
	bullet_list : List(List(Pandoc.Block)) -> Pandoc.Block
	bullet_list = |items| Pandoc.Block.BulletList(items)

	## Create a bullet list from plain-text items.
	##
	## Each string becomes a one-paragraph list item. Use `bullet_list` when an
	## item needs multiple paragraphs, code blocks, or other block structure.
	bullet_list_text : List(Str) -> Pandoc.Block
	bullet_list_text = |items| bullet_list(List.map(items, |item| [paragraph(item)]))

	## Create an ordered list starting at one with Pandoc's default marker style.
	##
	## Each item is a list of blocks, just as with `bullet_list`. Use
	## `Pandoc.Block.OrderedList` for another starting number, numbering style,
	## or delimiter.
	ordered_list : List(List(Pandoc.Block)) -> Pandoc.Block
	ordered_list = |items| Pandoc.Block.OrderedList(
		Pandoc.ListAttributes.{ start: 1, style: Pandoc.ListStyle.DefaultStyle, delimiter: Pandoc.ListDelimiter.DefaultDelim },
		items,
	)

	## Create an ordered list from plain-text items.
	##
	## Each string becomes a one-paragraph item and numbering starts at one.
	ordered_list_text : List(Str) -> Pandoc.Block
	ordered_list_text = |items| ordered_list(List.map(items, |item| [paragraph(item)]))

	## Wrap inline content in a span with empty attributes.
	##
	## An attribute-free span is mainly useful as a structural placeholder. Use
	## `Pandoc.Inline.Span` to attach an identifier, classes, or properties.
	span : List(Pandoc.Inline) -> Pandoc.Inline
	span = |inlines| Pandoc.Inline.Span(Pandoc.Attr.empty, inlines)

	## Wrap blocks in a division with empty attributes.
	##
	## An attribute-free division groups content without assigning an identifier
	## or class. Use `Pandoc.Block.Div` when output styling depends on attributes.
	div : List(Pandoc.Block) -> Pandoc.Block
	div = |blocks| Pandoc.Block.Div(Pandoc.Attr.empty, blocks)
}
