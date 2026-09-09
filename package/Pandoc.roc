## Construct a type-safe subset of the Pandoc abstract syntax tree and encode it
## as Pandoc JSON.
##
## Build a `Document` from `Block` and `Inline` values, then call
## `document.to_json()` (or `Pandoc.to_json(document)`). Strings, metadata keys,
## identifiers, classes, and attribute pairs are JSON-escaped automatically.
Pandoc := [].{

	## The Pandoc JSON API version emitted by this package.
	api_version : Str
	api_version = "1.23.1"

	## A complete Pandoc document containing metadata and block-level content.
	##
	## ```roc
	## document = Pandoc.Document.{
	##     meta: Dict.empty(),
	##     blocks: [Pandoc.Block.Para([Pandoc.Inline.String("Hello")])],
	## }
	## ```
	Document := { blocks : List(Block), meta : Dict(Str, MetaValue) }.{

		## Encode a complete document as Pandoc JSON.
		to_json : Document -> Str
		to_json = |document| document_to_json(document)
	}

	## A value in a document's metadata map.
	##
	## `Map` recursively contains metadata, while `Inlines` and `Blocks` allow
	## formatted Pandoc content in metadata fields such as titles and abstracts.
	##
	## ```roc
	## title = Pandoc.MetaValue.Inlines([
	##     Pandoc.Inline.Strong([Pandoc.Inline.String("Roc and Pandoc")]),
	## ])
	## ```
	MetaValue := [Map(Dict(Str, MetaValue)), List(List(MetaValue)), Bool(Bool), String(Str), Inlines(List(Inline)), Blocks(List(Block))].{

		## Encode one metadata value using Pandoc's tagged JSON representation.
		to_json : MetaValue -> Str
		to_json = |value| meta_to_json(value)
	}

	## Block-level document content.
	##
	## An `OrderedList` contains a list of items, where every item is itself a
	## list of blocks. The integer passed to `Header` is its heading level.
	##
	## ```roc
	## heading = Pandoc.Block.Header(
	##     2,
	##     Pandoc.Attr.empty,
	##     [Pandoc.Inline.String("Details")],
	## )
	## ```
	Block := [Plain(List(Inline)), Para(List(Inline)), LineBlock(List(List(Inline))), CodeBlock(Attr, Str), RawBlock(Str, Str), BlockQuote(List(Block)), OrderedList(ListAttributes, List(List(Block))), BulletList(List(List(Block))), DefinitionList(List(Definition)), Header(I32, Attr, List(Inline)), HorizontalRule, Table(Attr, Caption, List(ColSpec), TableHead, List(TableBody), TableFoot), Figure(Attr, Caption, List(Block)), Div(Attr, List(Block))].{

		## Encode one block using Pandoc's tagged JSON representation.
		to_json : Block -> Str
		to_json = |block| block_to_json(block)
	}

	## Inline text and formatting within a block.
	##
	## Formatting constructors contain more inline values and can therefore be
	## nested. Use `Space`, `SoftBreak`, and `LineBreak` rather than embedding
	## those layout choices in `String` values.
	##
	## ```roc
	## greeting = [
	##     Pandoc.Inline.Strong([Pandoc.Inline.String("Hello")]),
	##     Pandoc.Inline.Space,
	##     Pandoc.Inline.String("world"),
	## ]
	## ```
	Inline := [String(Str), Emph(List(Inline)), Underline(List(Inline)), Strong(List(Inline)), Strikeout(List(Inline)), Superscript(List(Inline)), Subscript(List(Inline)), SmallCaps(List(Inline)), Quoted(QuoteType, List(Inline)), Cite(List(Citation), List(Inline)), Code(Attr, Str), Space, SoftBreak, LineBreak, Math(MathType, Str), RawInline(Str, Str), Link(Attr, List(Inline), Target), Image(Attr, List(Inline), Target), Note(List(Block)), Span(Attr, List(Inline))].{

		## Encode one inline using Pandoc's tagged JSON representation.
		to_json : Inline -> Str
		to_json = |inline| inline_to_json(inline)
	}

	## An element identifier, CSS-style classes, and key-value attributes.
	##
	## ```roc
	## attr = Pandoc.Attr.{
	##     identifier: "example",
	##     classes: ["highlight"],
	##     attributes: [("lang", "roc")],
	## }
	## ```
	Attr := { identifier : Str, classes : List(Str), attributes : List((Str, Str)) }.{

		## Attributes with no identifier, classes, or key-value pairs.
		empty : Attr
		empty = { identifier: "", classes: [], attributes: [] }

		## Encode attributes as Pandoc's identifier, classes, and properties tuple.
		to_json : Attr -> Str
		to_json = |attr| attr_to_json(attr)
	}

	## A link or image destination and its optional title.
	Target := { url : Str, title : Str }.{

		## Encode a target as Pandoc's URL and title tuple.
		to_json : Target -> Str
		to_json = |target| target_to_json(target)
	}

	## The kind of quotation marks surrounding quoted inline content.
	QuoteType := [SingleQuote, DoubleQuote]

	## Whether math is rendered within a line or as its own display.
	MathType := [DisplayMath, InlineMath]

	## How a citation's author is presented.
	CitationMode := [AuthorInText, SuppressAuthor, NormalCitation]

	## One citation embedded in a `Cite` inline.
	Citation := { id : Str, prefix : List(Inline), suffix : List(Inline), mode : CitationMode, note_num : I64, hash : I64 }.{

		## Encode a citation record using Pandoc's required JSON field names.
		to_json : Citation -> Str
		to_json = |citation| citation_to_json(citation)
	}

	## A definition-list term and one or more alternative definitions.
	Definition := { term : List(Inline), definitions : List(List(Block)) }

	## A figure caption. `short` is used in lists of figures when present.
	Caption := { short : [None, Some(List(Inline))], long : List(Block) }.{

		## Encode the optional short caption and full block caption.
		to_json : Caption -> Str
		to_json = |caption| caption_to_json(caption)
	}

	## Horizontal alignment of a table column or cell.
	Alignment := [Left, Right, Center, Default]

	## A table column's default or fractional width.
	ColWidth := [Default, Fraction(F64)]

	## A table column's alignment and width specification.
	ColSpec := { alignment : Alignment, width : ColWidth }

	## Attributes and rows belonging to a table header.
	TableHead := { attr : Attr, rows : List(Row) }

	## One table body, including optional intermediate header rows.
	TableBody := { attr : Attr, row_head_columns : I32, intermediate_head : List(Row), body : List(Row) }

	## Attributes and rows belonging to a table footer.
	TableFoot := { attr : Attr, rows : List(Row) }

	## One table row and its cells.
	Row := { attr : Attr, cells : List(Cell) }

	## A table cell with alignment, spans, attributes, and block content.
	Cell := { attr : Attr, alignment : Alignment, row_span : I32, col_span : I32, blocks : List(Block) }

	## Numbering style for an ordered list.
	ListStyle := [DefaultStyle, Example, Decimal, LowerRoman, UpperRoman, LowerAlpha, UpperAlpha].{

		## Encode a list-numbering style tag.
		to_json : ListStyle -> Str
		to_json = |style| bare_tag(
			match style {
				DefaultStyle => "DefaultStyle"
				Example => "Example"
				Decimal => "Decimal"
				LowerRoman => "LowerRoman"
				UpperRoman => "UpperRoman"
				LowerAlpha => "LowerAlpha"
				UpperAlpha => "UpperAlpha"
			},
		)
	}

	## Punctuation surrounding an ordered-list marker.
	ListDelimiter := [DefaultDelim, Period, OneParen, TwoParens].{

		## Encode a list-marker delimiter tag.
		to_json : ListDelimiter -> Str
		to_json = |delimiter| bare_tag(
			match delimiter {
				DefaultDelim => "DefaultDelim"
				Period => "Period"
				OneParen => "OneParen"
				TwoParens => "TwoParens"
			},
		)
	}

	## Starting number, numbering style, and marker punctuation for an ordered list.
	##
	## ```roc
	## numbering = Pandoc.ListAttributes.{
	##     start: 1,
	##     style: Pandoc.ListStyle.Decimal,
	##     delimiter: Pandoc.ListDelimiter.Period,
	## }
	## ```
	ListAttributes := { start : I32, style : ListStyle, delimiter : ListDelimiter }.{

		## Encode the starting number, style, and delimiter tuple.
		to_json : ListAttributes -> Str
		to_json = |attributes| "[${attributes.start.to_str()},${attributes.style.to_json()},${attributes.delimiter.to_json()}]"
	}

	## Explicitly encode a complete document as Pandoc JSON.
	to_json : Document -> Str
	to_json = |document| document.to_json()

	## Low-level document encoder used by `Document.to_json`.
	document_to_json : Document -> Str
	document_to_json = |document| {
		version = Pandoc.api_version.replace_each(".", ",")
		metadata = Str.join_with(List.map(document.meta.to_list(), |(key, value)| "${Json.to_str(key)}:${meta_to_json(value)}"), ",")
		blocks = Str.join_with(List.map(document.blocks, |block| block_to_json(block)), ",")
		"{\"pandoc-api-version\":[${version}],\"meta\":{${metadata}},\"blocks\":[${blocks}]}"
	}

	## Low-level metadata encoder.
	meta_to_json : MetaValue -> Str
	meta_to_json = |value| match value {
		Map(map) => tagged("MetaMap", "{${Str.join_with(List.map(map.to_list(), |(key, item)| "${Json.to_str(key)}:${meta_to_json(item)}"), ",")}}")
		List(items) => tagged("MetaList", "[${Str.join_with(List.map(items, |item| meta_to_json(item)), ",")}]")
		Bool(bool) => tagged("MetaBool", Json.to_str(bool))
		String(str) => tagged("MetaString", Json.to_str(str))
		Inlines(inlines) => tagged("MetaInlines", inline_list_to_json(inlines))
		Blocks(blocks) => tagged("MetaBlocks", block_list_to_json(blocks))
	}

	## Low-level block encoder.
	block_to_json : Block -> Str
	block_to_json = |block| match block {
		Plain(inlines) => tagged("Plain", inline_list_to_json(inlines))
		Para(inlines) => tagged("Para", inline_list_to_json(inlines))
		LineBlock(lines) => tagged("LineBlock", "[${Str.join_with(List.map(lines, |line| inline_list_to_json(line)), ",")}]")
		CodeBlock(attr, contents) => tagged("CodeBlock", "[${attr_to_json(attr)},${Json.to_str(contents)}]")
		RawBlock(format, contents) => tagged("RawBlock", "[${Json.to_str(format)},${Json.to_str(contents)}]")
		BlockQuote(blocks) => tagged("BlockQuote", block_list_to_json(blocks))
		OrderedList(attributes, items) => tagged("OrderedList", "[${attributes.to_json()},[${Str.join_with(List.map(items, |item| block_list_to_json(item)), ",")}]]")
		BulletList(items) => tagged("BulletList", "[${Str.join_with(List.map(items, |item| block_list_to_json(item)), ",")}]")
		DefinitionList(items) => tagged("DefinitionList", "[${Str.join_with(List.map(items, |item| definition_to_json(item)), ",")}]")
		Header(level, attr, inlines) => tagged("Header", "[${level.to_str()},${attr_to_json(attr)},${inline_list_to_json(inlines)}]")
		HorizontalRule => bare_tag("HorizontalRule")
		Table(attr, caption, columns, head, bodies, foot) => tagged("Table", "[${attr_to_json(attr)},${caption_to_json(caption)},[${Str.join_with(List.map(columns, |column| col_spec_to_json(column)), ",")}],${table_head_to_json(head)},[${Str.join_with(List.map(bodies, |body| table_body_to_json(body)), ",")}],${table_foot_to_json(foot)}]")
		Figure(attr, caption, blocks) => tagged("Figure", "[${attr_to_json(attr)},${caption_to_json(caption)},${block_list_to_json(blocks)}]")
		Div(attr, blocks) => tagged("Div", "[${attr_to_json(attr)},${block_list_to_json(blocks)}]")
	}

	## Low-level inline encoder.
	inline_to_json : Inline -> Str
	inline_to_json = |inline| match inline {
		String(str) => tagged("Str", Json.to_str(str))
		Emph(items) => tagged("Emph", inline_list_to_json(items))
		Underline(items) => tagged("Underline", inline_list_to_json(items))
		Strong(items) => tagged("Strong", inline_list_to_json(items))
		Strikeout(items) => tagged("Strikeout", inline_list_to_json(items))
		Superscript(items) => tagged("Superscript", inline_list_to_json(items))
		Subscript(items) => tagged("Subscript", inline_list_to_json(items))
		SmallCaps(items) => tagged("SmallCaps", inline_list_to_json(items))
		Quoted(kind, items) => tagged("Quoted", "[${quote_type_to_json(kind)},${inline_list_to_json(items)}]")
		Cite(citations, items) => tagged("Cite", "[[${Str.join_with(List.map(citations, |citation| citation_to_json(citation)), ",")}],${inline_list_to_json(items)}]")
		Code(attr, contents) => tagged("Code", "[${attr_to_json(attr)},${Json.to_str(contents)}]")
		Space => bare_tag("Space")
		SoftBreak => bare_tag("SoftBreak")
		LineBreak => bare_tag("LineBreak")
		Math(kind, contents) => tagged("Math", "[${math_type_to_json(kind)},${Json.to_str(contents)}]")
		RawInline(format, contents) => tagged("RawInline", "[${Json.to_str(format)},${Json.to_str(contents)}]")
		Link(attr, description, target) => tagged("Link", "[${attr_to_json(attr)},${inline_list_to_json(description)},${target_to_json(target)}]")
		Image(attr, description, target) => tagged("Image", "[${attr_to_json(attr)},${inline_list_to_json(description)},${target_to_json(target)}]")
		Note(blocks) => tagged("Note", block_list_to_json(blocks))
		Span(attr, items) => tagged("Span", "[${attr_to_json(attr)},${inline_list_to_json(items)}]")
	}

	## Encode a JSON array of inline values.
	inline_list_to_json : List(Inline) -> Str
	inline_list_to_json = |items| "[${Str.join_with(List.map(items, |item| inline_to_json(item)), ",")}]"

	## Encode a JSON array of block values.
	block_list_to_json : List(Block) -> Str
	block_list_to_json = |items| "[${Str.join_with(List.map(items, |item| block_to_json(item)), ",")}]"

	## Low-level attribute tuple encoder.
	attr_to_json : Attr -> Str
	attr_to_json = |attr| {
		classes = Str.join_with(List.map(attr.classes, |class| Json.to_str(class)), ",")
		attributes = Str.join_with(List.map(attr.attributes, |(key, value)| "[${Json.to_str(key)},${Json.to_str(value)}]"), ",")
		"[${Json.to_str(attr.identifier)},[${classes}],[${attributes}]]"
	}

	## Low-level link and image target encoder.
	target_to_json : Target -> Str
	target_to_json = |target| "[${Json.to_str(target.url)},${Json.to_str(target.title)}]"

	## Low-level quotation-kind encoder.
	quote_type_to_json : QuoteType -> Str
	quote_type_to_json = |kind| bare_tag(
		match kind {
			SingleQuote => "SingleQuote"
			DoubleQuote => "DoubleQuote"
		},
	)

	## Low-level math-kind encoder.
	math_type_to_json : MathType -> Str
	math_type_to_json = |kind| bare_tag(
		match kind {
			DisplayMath => "DisplayMath"
			InlineMath => "InlineMath"
		},
	)

	## Low-level citation-mode encoder.
	citation_mode_to_json : CitationMode -> Str
	citation_mode_to_json = |mode| bare_tag(
		match mode {
			AuthorInText => "AuthorInText"
			SuppressAuthor => "SuppressAuthor"
			NormalCitation => "NormalCitation"
		},
	)

	## Low-level citation record encoder.
	citation_to_json : Citation -> Str
	citation_to_json = |citation| "{\"citationId\":${Json.to_str(citation.id)},\"citationPrefix\":${inline_list_to_json(citation.prefix)},\"citationSuffix\":${inline_list_to_json(citation.suffix)},\"citationMode\":${citation_mode_to_json(citation.mode)},\"citationNoteNum\":${citation.note_num.to_str()},\"citationHash\":${citation.hash.to_str()}}"

	## Low-level definition-list entry encoder.
	definition_to_json : Definition -> Str
	definition_to_json = |definition| "[${inline_list_to_json(definition.term)},[${Str.join_with(List.map(definition.definitions, |blocks| block_list_to_json(blocks)), ",")}]]"

	## Low-level table and figure caption encoder.
	caption_to_json : Caption -> Str
	caption_to_json = |caption| {
		short = match caption.short {
			None => "null"
			Some(inlines) => inline_list_to_json(inlines)
		}
		"[${short},${block_list_to_json(caption.long)}]"
	}

	## Low-level table alignment encoder.
	alignment_to_json : Alignment -> Str
	alignment_to_json = |alignment| bare_tag(
		match alignment {
			Left => "AlignLeft"
			Right => "AlignRight"
			Center => "AlignCenter"
			Default => "AlignDefault"
		},
	)

	## Low-level table column-width encoder.
	col_width_to_json : ColWidth -> Str
	col_width_to_json = |width| match width {
		Default => bare_tag("ColWidthDefault")
		Fraction(value) => tagged("ColWidth", value.to_str())
	}

	## Low-level table column specification encoder.
	col_spec_to_json : ColSpec -> Str
	col_spec_to_json = |column| "[${alignment_to_json(column.alignment)},${col_width_to_json(column.width)}]"

	## Low-level table row encoder.
	row_to_json : Row -> Str
	row_to_json = |row| "[${attr_to_json(row.attr)},[${Str.join_with(List.map(row.cells, |cell| cell_to_json(cell)), ",")}]]"

	## Low-level table cell encoder.
	cell_to_json : Cell -> Str
	cell_to_json = |cell| "[${attr_to_json(cell.attr)},${alignment_to_json(cell.alignment)},${cell.row_span.to_str()},${cell.col_span.to_str()},${block_list_to_json(cell.blocks)}]"

	## Low-level table header encoder.
	table_head_to_json : TableHead -> Str
	table_head_to_json = |head| "[${attr_to_json(head.attr)},[${Str.join_with(List.map(head.rows, |row| row_to_json(row)), ",")}]]"

	## Low-level table body encoder.
	table_body_to_json : TableBody -> Str
	table_body_to_json = |body| "[${attr_to_json(body.attr)},${body.row_head_columns.to_str()},[${Str.join_with(List.map(body.intermediate_head, |row| row_to_json(row)), ",")}],[${Str.join_with(List.map(body.body, |row| row_to_json(row)), ",")}]]"

	## Low-level table footer encoder.
	table_foot_to_json : TableFoot -> Str
	table_foot_to_json = |foot| "[${attr_to_json(foot.attr)},[${Str.join_with(List.map(foot.rows, |row| row_to_json(row)), ",")}]]"

	## Encode a Pandoc JSON object with both `t` and `c` fields.
	tagged : Str, Str -> Str
	tagged = |tag, contents| "{\"t\":${Json.to_str(tag)},\"c\":${contents}}"

	## Encode a Pandoc JSON object containing only a `t` field.
	bare_tag : Str -> Str
	bare_tag = |tag| "{\"t\":${Json.to_str(tag)}}"
}

expect Pandoc.Document.{ meta: Dict.empty(), blocks: [] }.to_json() == "{\"pandoc-api-version\":[1,23,1],\"meta\":{},\"blocks\":[]}"
expect Pandoc.Inline.String("quotes: \" and slash: \\").to_json() == "{\"t\":\"Str\",\"c\":\"quotes: \\\" and slash: \\\\\"}"
expect Pandoc.Block.Header(1, Pandoc.Attr.{ identifier: "intro", classes: ["lead"], attributes: [("role", "doc")] }, [Pandoc.Inline.String("Hello")]).to_json() == "{\"t\":\"Header\",\"c\":[1,[\"intro\",[\"lead\"],[[\"role\",\"doc\"]]],[{\"t\":\"Str\",\"c\":\"Hello\"}]]}"

expect {
	metadata = Dict.empty()
		|> Dict.insert("published", Pandoc.MetaValue.Bool(True))
		|> Dict.insert("authors", Pandoc.MetaValue.List([Pandoc.MetaValue.String("Ada")]))
	json = Pandoc.Document.{ meta: metadata, blocks: [] }.to_json()
	json == "{\"pandoc-api-version\":[1,23,1],\"meta\":{\"published\":{\"t\":\"MetaBool\",\"c\":true},\"authors\":{\"t\":\"MetaList\",\"c\":[{\"t\":\"MetaString\",\"c\":\"Ada\"}]}},\"blocks\":[]}"
}

expect Pandoc.Block.OrderedList(
	Pandoc.ListAttributes.{ start: 3, style: Pandoc.ListStyle.LowerRoman, delimiter: Pandoc.ListDelimiter.OneParen },
	[[Pandoc.Block.Plain([Pandoc.Inline.String("item")])]],
).to_json() == "{\"t\":\"OrderedList\",\"c\":[[3,{\"t\":\"LowerRoman\"},{\"t\":\"OneParen\"}],[[{\"t\":\"Plain\",\"c\":[{\"t\":\"Str\",\"c\":\"item\"}]}]]]}"

expect Pandoc.Block.Para([
	Pandoc.Inline.Emph([Pandoc.Inline.String("em")]),
	Pandoc.Inline.Space,
	Pandoc.Inline.Strong([Pandoc.Inline.String("strong")]),
	Pandoc.Inline.SoftBreak,
	Pandoc.Inline.LineBreak,
]).to_json() == "{\"t\":\"Para\",\"c\":[{\"t\":\"Emph\",\"c\":[{\"t\":\"Str\",\"c\":\"em\"}]},{\"t\":\"Space\"},{\"t\":\"Strong\",\"c\":[{\"t\":\"Str\",\"c\":\"strong\"}]},{\"t\":\"SoftBreak\"},{\"t\":\"LineBreak\"}]}"
