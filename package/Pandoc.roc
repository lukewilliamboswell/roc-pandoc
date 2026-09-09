## Construct a type-safe subset of the Pandoc abstract syntax tree and encode it
## as Pandoc JSON.
##
## Build a `Document` from `Block` and `Inline` values, then call
## `Json.to_str(document)`. Strings, metadata keys,
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

		## Encode a complete document using Roc's generic encoding protocol.
		encoder_for : _
		encoder_for = |encoding| |document, state| encode_json_value(encoding, document_to_value(document), state)
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
	MetaValue := [Map(Dict(Str, MetaValue)), List(List(MetaValue)), Bool(Bool), String(Str), Inlines(List(Inline)), Blocks(List(Block))]

	## Block-level document content.
	##
	## An `OrderedList` contains a list of items, where every item is itself a
	## list of blocks. `BulletList` has the same nested item shape. The integer
	## passed to `Header` is its heading level. `RawBlock` takes a format name and
	## source text; `CodeBlock`, `Header`, `Figure`, and `Div` carry attributes.
	## `Table` follows Pandoc's six-part table model: attributes, caption, column
	## specifications, head, bodies, and foot.
	##
	## ```roc
	## heading = Pandoc.Block.Header(
	##     2,
	##     Pandoc.Attr.empty,
	##     [Pandoc.Inline.String("Details")],
	## )
	## ```
	Block := [Plain(List(Inline)), Para(List(Inline)), LineBlock(List(List(Inline))), CodeBlock(Attr, Str), RawBlock(Str, Str), BlockQuote(List(Block)), OrderedList(ListAttributes, List(List(Block))), BulletList(List(List(Block))), DefinitionList(List(Definition)), Header(I32, Attr, List(Inline)), HorizontalRule, Table(Attr, Caption, List(ColSpec), TableHead, List(TableBody), TableFoot), Figure(Attr, Caption, List(Block)), Div(Attr, List(Block))]

	## Inline text and formatting within a block.
	##
	## Formatting constructors contain more inline values and can therefore be
	## nested. Use `Space`, `SoftBreak`, and `LineBreak` rather than embedding
	## those layout choices in `String` values. `RawInline` takes a format name
	## and source text. `Link` and `Image` take attributes, visible or alternative
	## inline content, and a target. `Cite` stores citation records alongside the
	## rendered fallback inlines, while `Note` contains block-level footnote text.
	##
	## ```roc
	## greeting = [
	##     Pandoc.Inline.Strong([Pandoc.Inline.String("Hello")]),
	##     Pandoc.Inline.Space,
	##     Pandoc.Inline.String("world"),
	## ]
	## ```
	Inline := [String(Str), Emph(List(Inline)), Underline(List(Inline)), Strong(List(Inline)), Strikeout(List(Inline)), Superscript(List(Inline)), Subscript(List(Inline)), SmallCaps(List(Inline)), Quoted(QuoteType, List(Inline)), Cite(List(Citation), List(Inline)), Code(Attr, Str), Space, SoftBreak, LineBreak, Math(MathType, Str), RawInline(Str, Str), Link(Attr, List(Inline), Target), Image(Attr, List(Inline), Target), Note(List(Block)), Span(Attr, List(Inline))]

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

	}

	## A link or image destination and its optional title.
	Target := { url : Str, title : Str }

	## The kind of quotation marks surrounding quoted inline content.
	QuoteType := [SingleQuote, DoubleQuote]

	## Whether math is rendered within a line or as its own display.
	MathType := [DisplayMath, InlineMath]

	## How a citation's author is presented.
	CitationMode := [AuthorInText, SuppressAuthor, NormalCitation]

	## One citation embedded in a `Cite` inline.
	Citation := { id : Str, prefix : List(Inline), suffix : List(Inline), mode : CitationMode, note_num : I64, hash : I64 }

	## A definition-list term and one or more alternative definitions.
	Definition := { term : List(Inline), definitions : List(List(Block)) }

	## A figure caption. `short` is used in lists of figures when present.
	Caption := { short : [None, Some(List(Inline))], long : List(Block) }

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
	ListStyle := [DefaultStyle, Example, Decimal, LowerRoman, UpperRoman, LowerAlpha, UpperAlpha]

	## Punctuation surrounding an ordered-list marker.
	ListDelimiter := [DefaultDelim, Period, OneParen, TwoParens]

	## Starting number, numbering style, and marker punctuation for an ordered list.
	##
	## ```roc
	## numbering = Pandoc.ListAttributes.{
	##     start: 1,
	##     style: Pandoc.ListStyle.Decimal,
	##     delimiter: Pandoc.ListDelimiter.Period,
	## }
	## ```
	ListAttributes := { start : I32, style : ListStyle, delimiter : ListDelimiter }
}

JsonValue := [Array(List(JsonValue)), Object(List((Str, JsonValue))), StringValue(Str), BoolValue(Bool), I32Value(I32), I64Value(I64), F64Value(F64), Null]

encode_json_value : _, JsonValue, _ -> _
encode_json_value = |encoding, value, state| match value {
	StringValue(str) => Json.encode_str(encoding, str, state)
	BoolValue(bool) => Json.encode_bool(encoding, bool, state)
	I32Value(number) => Json.encode_i32(encoding, number, state)
	I64Value(number) => Json.encode_i64(encoding, number, state)
	F64Value(number) => match Json.encode_f64(encoding, number, state) {
		Ok(next) => Ok(next)
		Err(NaN) => crash "Pandoc column widths must be finite"
		Err(Infinity) => crash "Pandoc column widths must be finite"
		Err(NegativeInfinity) => crash "Pandoc column widths must be finite"
	}
	Null => Json.encode_null(encoding, state)
	Array(items) => Json.encode_list(encoding, state, items.len(), |container, write_item| encode_json_values(encoding, items, container, write_item))
	Object(fields) => Json.encode_record(encoding, state, fields.len(), |container, write_field| encode_json_fields(encoding, fields, container, write_field))
}

encode_json_values : _, List(JsonValue), _, _ -> _
encode_json_values = |encoding, items, container, write_item| match items {
	[] => Ok(container)
	[first, .. as rest] => {
		next = write_item(container, |state| encode_json_value(encoding, first, state))?
		encode_json_values(encoding, rest, next, write_item)
	}
}

encode_json_fields : _, List((Str, JsonValue)), _, _ -> _
encode_json_fields = |encoding, fields, container, write_field| match fields {
	[] => Ok(container)
	[(name, value), .. as rest] => {
		next = write_field(container, name, |state| encode_json_value(encoding, value, state))?
		encode_json_fields(encoding, rest, next, write_field)
	}
}

document_to_value : Pandoc.Document -> JsonValue
document_to_value = |document| JsonValue.Object([
	("pandoc-api-version", api_version_to_value()),
	("meta", JsonValue.Object(List.map(document.meta.to_list(), |(key, value)| (key, meta_to_value(value))))),
	("blocks", blocks_to_value(document.blocks)),
])

api_version_to_value : () -> JsonValue
api_version_to_value = || JsonValue.Array(
	List.map(
		Pandoc.api_version.split_on("."),
		|component|
			match I32.from_str(component) {
				Ok(number) => JsonValue.I32Value(number)
				Err(BadNumStr) => crash "Pandoc.api_version must contain dot-separated integers"
			},
	),
)

meta_to_value : Pandoc.MetaValue -> JsonValue
meta_to_value = |value| match value {
	Map(map) => tagged_value("MetaMap", JsonValue.Object(List.map(map.to_list(), |(key, item)| (key, meta_to_value(item)))))
	List(items) => tagged_value("MetaList", JsonValue.Array(List.map(items, meta_to_value)))
	Bool(bool) => tagged_value("MetaBool", JsonValue.BoolValue(bool))
	String(str) => tagged_value("MetaString", JsonValue.StringValue(str))
	Inlines(inlines) => tagged_value("MetaInlines", inlines_to_value(inlines))
	Blocks(blocks) => tagged_value("MetaBlocks", blocks_to_value(blocks))
}

blocks_to_value : List(Pandoc.Block) -> JsonValue
blocks_to_value = |blocks| JsonValue.Array(List.map(blocks, block_to_value))

inlines_to_value : List(Pandoc.Inline) -> JsonValue
inlines_to_value = |inlines| JsonValue.Array(List.map(inlines, inline_to_value))

block_to_value : Pandoc.Block -> JsonValue
block_to_value = |block| match block {
	Plain(xs) => tagged_value("Plain", inlines_to_value(xs))
	Para(xs) => tagged_value("Para", inlines_to_value(xs))
	LineBlock(lines) => tagged_value("LineBlock", JsonValue.Array(List.map(lines, inlines_to_value)))
	CodeBlock(attr, text) => tagged_value("CodeBlock", JsonValue.Array([attr_to_value(attr), JsonValue.StringValue(text)]))
	RawBlock(format, text) => tagged_value("RawBlock", JsonValue.Array([JsonValue.StringValue(format), JsonValue.StringValue(text)]))
	BlockQuote(blocks) => tagged_value("BlockQuote", blocks_to_value(blocks))
	OrderedList(attrs, items) => tagged_value("OrderedList", JsonValue.Array([list_attributes_to_value(attrs), JsonValue.Array(List.map(items, blocks_to_value))]))
	BulletList(items) => tagged_value("BulletList", JsonValue.Array(List.map(items, blocks_to_value)))
	DefinitionList(items) => tagged_value("DefinitionList", JsonValue.Array(List.map(items, definition_to_value)))
	Header(level, attr, xs) => tagged_value("Header", JsonValue.Array([JsonValue.I32Value(level), attr_to_value(attr), inlines_to_value(xs)]))
	HorizontalRule => bare_tag_value("HorizontalRule")
	Table(attr, caption, columns, head, bodies, foot) => tagged_value("Table", JsonValue.Array([attr_to_value(attr), caption_to_value(caption), JsonValue.Array(List.map(columns, col_spec_to_value)), table_head_to_value(head), JsonValue.Array(List.map(bodies, table_body_to_value)), table_foot_to_value(foot)]))
	Figure(attr, caption, blocks) => tagged_value("Figure", JsonValue.Array([attr_to_value(attr), caption_to_value(caption), blocks_to_value(blocks)]))
	Div(attr, blocks) => tagged_value("Div", JsonValue.Array([attr_to_value(attr), blocks_to_value(blocks)]))
}

inline_to_value : Pandoc.Inline -> JsonValue
inline_to_value = |inline| match inline {
	String(str) => tagged_value("Str", JsonValue.StringValue(str))
	Emph(xs) => tagged_value("Emph", inlines_to_value(xs))
	Underline(xs) => tagged_value("Underline", inlines_to_value(xs))
	Strong(xs) => tagged_value("Strong", inlines_to_value(xs))
	Strikeout(xs) => tagged_value("Strikeout", inlines_to_value(xs))
	Superscript(xs) => tagged_value("Superscript", inlines_to_value(xs))
	Subscript(xs) => tagged_value("Subscript", inlines_to_value(xs))
	SmallCaps(xs) => tagged_value("SmallCaps", inlines_to_value(xs))
	Quoted(kind, xs) => tagged_value("Quoted", JsonValue.Array([quote_type_to_value(kind), inlines_to_value(xs)]))
	Cite(citations, xs) => tagged_value("Cite", JsonValue.Array([JsonValue.Array(List.map(citations, citation_to_value)), inlines_to_value(xs)]))
	Code(attr, text) => tagged_value("Code", JsonValue.Array([attr_to_value(attr), JsonValue.StringValue(text)]))
	Space => bare_tag_value("Space")
	SoftBreak => bare_tag_value("SoftBreak")
	LineBreak => bare_tag_value("LineBreak")
	Math(kind, text) => tagged_value("Math", JsonValue.Array([math_type_to_value(kind), JsonValue.StringValue(text)]))
	RawInline(format, text) => tagged_value("RawInline", JsonValue.Array([JsonValue.StringValue(format), JsonValue.StringValue(text)]))
	Link(attr, xs, target) => tagged_value("Link", JsonValue.Array([attr_to_value(attr), inlines_to_value(xs), target_to_value(target)]))
	Image(attr, xs, target) => tagged_value("Image", JsonValue.Array([attr_to_value(attr), inlines_to_value(xs), target_to_value(target)]))
	Note(blocks) => tagged_value("Note", blocks_to_value(blocks))
	Span(attr, xs) => tagged_value("Span", JsonValue.Array([attr_to_value(attr), inlines_to_value(xs)]))
}

attr_to_value : Pandoc.Attr -> JsonValue
attr_to_value = |attr| JsonValue.Array([JsonValue.StringValue(attr.identifier), JsonValue.Array(List.map(attr.classes, |class| JsonValue.StringValue(class))), JsonValue.Array(List.map(attr.attributes, |(key, value)| JsonValue.Array([JsonValue.StringValue(key), JsonValue.StringValue(value)])))])

target_to_value : Pandoc.Target -> JsonValue
target_to_value = |target| JsonValue.Array([JsonValue.StringValue(target.url), JsonValue.StringValue(target.title)])

quote_type_to_value : Pandoc.QuoteType -> JsonValue
quote_type_to_value = |kind| bare_tag_value(
	match kind {
		SingleQuote => "SingleQuote"
		DoubleQuote => "DoubleQuote"
	},
)

math_type_to_value : Pandoc.MathType -> JsonValue
math_type_to_value = |kind| bare_tag_value(
	match kind {
		DisplayMath => "DisplayMath"
		InlineMath => "InlineMath"
	},
)

citation_mode_to_value : Pandoc.CitationMode -> JsonValue
citation_mode_to_value = |mode| bare_tag_value(
	match mode {
		AuthorInText => "AuthorInText"
		SuppressAuthor => "SuppressAuthor"
		NormalCitation => "NormalCitation"
	},
)

citation_to_value : Pandoc.Citation -> JsonValue
citation_to_value = |c| JsonValue.Object([("citationId", JsonValue.StringValue(c.id)), ("citationPrefix", inlines_to_value(c.prefix)), ("citationSuffix", inlines_to_value(c.suffix)), ("citationMode", citation_mode_to_value(c.mode)), ("citationNoteNum", JsonValue.I64Value(c.note_num)), ("citationHash", JsonValue.I64Value(c.hash))])

definition_to_value : Pandoc.Definition -> JsonValue
definition_to_value = |d| JsonValue.Array([inlines_to_value(d.term), JsonValue.Array(List.map(d.definitions, blocks_to_value))])

caption_to_value : Pandoc.Caption -> JsonValue
caption_to_value = |caption| JsonValue.Array([
	match caption.short {
		None => JsonValue.Null
		Some(xs) => inlines_to_value(xs)
	},
	blocks_to_value(caption.long),
])

alignment_to_value : Pandoc.Alignment -> JsonValue
alignment_to_value = |alignment| bare_tag_value(
	match alignment {
		Left => "AlignLeft"
		Right => "AlignRight"
		Center => "AlignCenter"
		Default => "AlignDefault"
	},
)

col_width_to_value : Pandoc.ColWidth -> JsonValue
col_width_to_value = |width| match width {
	Default => bare_tag_value("ColWidthDefault")
	Fraction(value) => tagged_value("ColWidth", JsonValue.F64Value(value))
}

col_spec_to_value : Pandoc.ColSpec -> JsonValue
col_spec_to_value = |column| JsonValue.Array([alignment_to_value(column.alignment), col_width_to_value(column.width)])

row_to_value : Pandoc.Row -> JsonValue
row_to_value = |row| JsonValue.Array([attr_to_value(row.attr), JsonValue.Array(List.map(row.cells, cell_to_value))])

cell_to_value : Pandoc.Cell -> JsonValue
cell_to_value = |cell| JsonValue.Array([attr_to_value(cell.attr), alignment_to_value(cell.alignment), JsonValue.I32Value(cell.row_span), JsonValue.I32Value(cell.col_span), blocks_to_value(cell.blocks)])

table_head_to_value : Pandoc.TableHead -> JsonValue
table_head_to_value = |head| JsonValue.Array([attr_to_value(head.attr), JsonValue.Array(List.map(head.rows, row_to_value))])

table_body_to_value : Pandoc.TableBody -> JsonValue
table_body_to_value = |body| JsonValue.Array([attr_to_value(body.attr), JsonValue.I32Value(body.row_head_columns), JsonValue.Array(List.map(body.intermediate_head, row_to_value)), JsonValue.Array(List.map(body.body, row_to_value))])

table_foot_to_value : Pandoc.TableFoot -> JsonValue
table_foot_to_value = |foot| JsonValue.Array([attr_to_value(foot.attr), JsonValue.Array(List.map(foot.rows, row_to_value))])

list_attributes_to_value : Pandoc.ListAttributes -> JsonValue
list_attributes_to_value = |attrs| JsonValue.Array([JsonValue.I32Value(attrs.start), list_style_to_value(attrs.style), list_delimiter_to_value(attrs.delimiter)])

list_style_to_value : Pandoc.ListStyle -> JsonValue
list_style_to_value = |style| bare_tag_value(
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

list_delimiter_to_value : Pandoc.ListDelimiter -> JsonValue
list_delimiter_to_value = |delimiter| bare_tag_value(
	match delimiter {
		DefaultDelim => "DefaultDelim"
		Period => "Period"
		OneParen => "OneParen"
		TwoParens => "TwoParens"
	},
)

tagged_value = |tag, contents| JsonValue.Object([("t", JsonValue.StringValue(tag)), ("c", contents)])

bare_tag_value = |tag| JsonValue.Object([("t", JsonValue.StringValue(tag))])

expect Json.to_str(Pandoc.Document.{ meta: Dict.empty(), blocks: [] }) == "{\"pandoc-api-version\":[1,23,1],\"meta\":{},\"blocks\":[]}"

expect {
	metadata = Dict.empty()
		|> Dict.insert("published", Pandoc.MetaValue.Bool(True))
		|> Dict.insert("authors", Pandoc.MetaValue.List([Pandoc.MetaValue.String("Ada")]))
	json = Json.to_str(Pandoc.Document.{ meta: metadata, blocks: [] })
	json == "{\"pandoc-api-version\":[1,23,1],\"meta\":{\"published\":{\"t\":\"MetaBool\",\"c\":true},\"authors\":{\"t\":\"MetaList\",\"c\":[{\"t\":\"MetaString\",\"c\":\"Ada\"}]}},\"blocks\":[]}"
}
