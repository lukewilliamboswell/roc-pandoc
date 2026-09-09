## Types and JSON encoding for the Pandoc abstract syntax tree.
Pandoc := [].{

	## A complete Pandoc document.
	Document := { blocks : List(Block), meta : Dict(Str, MetaValue) }.{

		## Encode this document to Pandoc's JSON format.
		to_json : Document -> Str
		to_json = |document| document_to_json(document)
	}

	MetaValue := [Map(Dict(Str, MetaValue)), List(List(MetaValue)), Bool(Bool), String(Str), Inlines(List(Inline)), Blocks(List(Block))].{
		to_json : MetaValue -> Str
		to_json = |value| meta_to_json(value)
	}

	Block := [Plain(List(Inline)), Para(List(Inline)), LineBlock(List(List(Inline))), CodeBlock(Attr, Str), OrderedList(ListAttributes, List(List(Block))), Header(I32, Attr, List(Inline))].{
		to_json : Block -> Str
		to_json = |block| block_to_json(block)
	}

	Inline := [String(Str), Emph(List(Inline)), Underline(List(Inline)), Strong(List(Inline)), Strikeout(List(Inline)), Superscript(List(Inline)), Subscript(List(Inline)), SmallCaps(List(Inline)), Space, SoftBreak, LineBreak].{
		to_json : Inline -> Str
		to_json = |inline| inline_to_json(inline)
	}

	Attr := { identifier : Str, classes : List(Str), attributes : List((Str, Str)) }.{
		empty : Attr
		empty = { identifier: "", classes: [], attributes: [] }

		to_json : Attr -> Str
		to_json = |attr| attr_to_json(attr)
	}

	ListStyle := [DefaultStyle, Example, Decimal, LowerRoman, UpperRoman, LowerAlpha, UpperAlpha].{
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

	ListDelimiter := [DefaultDelim, Period, OneParen, TwoParens].{
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

	ListAttributes := { start : I32, style : ListStyle, delimiter : ListDelimiter }.{
		to_json : ListAttributes -> Str
		to_json = |attributes| "[${attributes.start.to_str()},${attributes.style.to_json()},${attributes.delimiter.to_json()}]"
	}

	## Convenience alias for `Document.to_json`.
	to_json : Document -> Str
	to_json = |document| document.to_json()

	document_to_json : Document -> Str
	document_to_json = |document| {
		metadata = Str.join_with(List.map(document.meta.to_list(), |(key, value)| "${Json.to_str(key)}:${meta_to_json(value)}"), ",")
		blocks = Str.join_with(List.map(document.blocks, |block| block_to_json(block)), ",")
		"{\"pandoc-api-version\":[1,23,1],\"meta\":{${metadata}},\"blocks\":[${blocks}]}"
	}

	meta_to_json : MetaValue -> Str
	meta_to_json = |value| match value {
		Map(map) => "{${Str.join_with(List.map(map.to_list(), |(key, item)| "${Json.to_str(key)}:${meta_to_json(item)}"), ",")}}"
		List(items) => tagged("MetaList", "[${Str.join_with(List.map(items, |item| meta_to_json(item)), ",")}]")
		Bool(bool) => tagged("MetaBool", Json.to_str(bool))
		String(str) => tagged("MetaString", Json.to_str(str))
		Inlines(inlines) => tagged("MetaInlines", inline_list_to_json(inlines))
		Blocks(blocks) => tagged("MetaBlocks", block_list_to_json(blocks))
	}

	block_to_json : Block -> Str
	block_to_json = |block| match block {
		Plain(inlines) => tagged("Plain", inline_list_to_json(inlines))
		Para(inlines) => tagged("Para", inline_list_to_json(inlines))
		LineBlock(lines) => tagged("LineBlock", "[${Str.join_with(List.map(lines, |line| inline_list_to_json(line)), ",")}]")
		CodeBlock(attr, contents) => tagged("CodeBlock", "[${attr_to_json(attr)},${Json.to_str(contents)}]")
		OrderedList(attributes, items) => tagged("OrderedList", "[${attributes.to_json()},[${Str.join_with(List.map(items, |item| block_list_to_json(item)), ",")}]]")
		Header(level, attr, inlines) => tagged("Header", "[${level.to_str()},${attr_to_json(attr)},${inline_list_to_json(inlines)}]")
	}

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
		Space => bare_tag("Space")
		SoftBreak => bare_tag("SoftBreak")
		LineBreak => bare_tag("LineBreak")
	}

	inline_list_to_json : List(Inline) -> Str
	inline_list_to_json = |items| "[${Str.join_with(List.map(items, |item| inline_to_json(item)), ",")}]"
	block_list_to_json : List(Block) -> Str
	block_list_to_json = |items| "[${Str.join_with(List.map(items, |item| block_to_json(item)), ",")}]"

	attr_to_json : Attr -> Str
	attr_to_json = |attr| {
		classes = Str.join_with(List.map(attr.classes, |class| Json.to_str(class)), ",")
		attributes = Str.join_with(List.map(attr.attributes, |(key, value)| "[${Json.to_str(key)},${Json.to_str(value)}]"), ",")
		"[${Json.to_str(attr.identifier)},[${classes}],[${attributes}]]"
	}

	tagged : Str, Str -> Str
	tagged = |tag, contents| "{\"t\":${Json.to_str(tag)},\"c\":${contents}}"
	bare_tag : Str -> Str
	bare_tag = |tag| "{\"t\":${Json.to_str(tag)}}"
}

expect Pandoc.to_json(Pandoc.Document.{ meta: Dict.empty(), blocks: [] }) == "{\"pandoc-api-version\":[1,23,1],\"meta\":{},\"blocks\":[]}"
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
