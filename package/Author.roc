## Ergonomic constructors for authoring Pandoc documents.
##
## Every helper returns the exact AST types from `Pandoc`, so high-level and
## advanced construction can be freely mixed in the same document.
import Pandoc

Author := [].{

	## Create a document with no metadata from a list of blocks.
	document : List(Pandoc.Block) -> Pandoc.Document
	document = |blocks| Pandoc.Document.{ meta: Dict.empty(), blocks }

	## Replace a document's metadata while preserving its blocks.
	with_meta : Pandoc.Document, Dict(Str, Pandoc.MetaValue) -> Pandoc.Document
	with_meta = |doc, meta| Pandoc.Document.{ meta, blocks: doc.blocks }

	## Create an inline string.
	text : Str -> Pandoc.Inline
	text = |value| Pandoc.Inline.String(value)

	## Create a paragraph containing one inline string.
	paragraph : Str -> Pandoc.Block
	paragraph = |value| Pandoc.Block.Para([text(value)])

	## Create a paragraph from already formatted inline content.
	paragraph_inlines : List(Pandoc.Inline) -> Pandoc.Block
	paragraph_inlines = |inlines| Pandoc.Block.Para(inlines)

	## Create an unadorned heading from a level and plain text.
	heading : I32, Str -> Pandoc.Block
	heading = |level, value| Pandoc.Block.Header(level, Pandoc.Attr.empty, [text(value)])

	## Create an unadorned heading from formatted inline content.
	heading_inlines : I32, List(Pandoc.Inline) -> Pandoc.Block
	heading_inlines = |level, inlines| Pandoc.Block.Header(level, Pandoc.Attr.empty, inlines)

	## Emphasize a plain string.
	emph : Str -> Pandoc.Inline
	emph = |value| Pandoc.Inline.Emph([text(value)])

	## Strongly emphasize a plain string.
	strong : Str -> Pandoc.Inline
	strong = |value| Pandoc.Inline.Strong([text(value)])

	## Create inline code with empty attributes.
	code : Str -> Pandoc.Inline
	code = |value| Pandoc.Inline.Code(Pandoc.Attr.empty, value)

	## Create a code block with empty attributes.
	code_block : Str -> Pandoc.Block
	code_block = |value| Pandoc.Block.CodeBlock(Pandoc.Attr.empty, value)

	## Create a link with a plain-text label and no title.
	link : Str, Str -> Pandoc.Inline
	link = |label, url| Pandoc.Inline.Link(Pandoc.Attr.empty, [text(label)], Pandoc.Target.{ url, title: "" })

	## Create an image with a plain-text description and no title.
	image : Str, Str -> Pandoc.Inline
	image = |description, url| Pandoc.Inline.Image(Pandoc.Attr.empty, [text(description)], Pandoc.Target.{ url, title: "" })

	## Wrap blocks in a block quotation.
	block_quote : List(Pandoc.Block) -> Pandoc.Block
	block_quote = |blocks| Pandoc.Block.BlockQuote(blocks)

	## Create a bullet list. Each outer item is a list of blocks.
	bullet_list : List(List(Pandoc.Block)) -> Pandoc.Block
	bullet_list = |items| Pandoc.Block.BulletList(items)

	## Create a list starting at one with Pandoc's default marker style.
	ordered_list : List(List(Pandoc.Block)) -> Pandoc.Block
	ordered_list = |items| Pandoc.Block.OrderedList(
		Pandoc.ListAttributes.{ start: 1, style: Pandoc.ListStyle.DefaultStyle, delimiter: Pandoc.ListDelimiter.DefaultDelim },
		items,
	)

	## Wrap inline content in a span with empty attributes.
	span : List(Pandoc.Inline) -> Pandoc.Inline
	span = |inlines| Pandoc.Inline.Span(Pandoc.Attr.empty, inlines)

	## Wrap blocks in a division with empty attributes.
	div : List(Pandoc.Block) -> Pandoc.Block
	div = |blocks| Pandoc.Block.Div(Pandoc.Attr.empty, blocks)
}
