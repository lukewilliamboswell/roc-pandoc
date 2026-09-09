# roc-pandoc

A Roc package for constructing Pandoc documents and encoding them to Pandoc's JSON AST format.

The package targets `nightly-2026-09-08-39a3f89` and uses nominal types with statically dispatched associated methods. String values and dictionary keys are escaped by Roc's built-in `Json` encoder.

## Example

```roc
document = Pandoc.Document.{
	meta: Dict.empty() |> Dict.insert("isBasic", Pandoc.MetaValue.Bool(True)),
	blocks: [
		Pandoc.Block.Header(1, Pandoc.Attr.empty, [Pandoc.Inline.String("Hello")]),
		Pandoc.Block.Para([Pandoc.Inline.String("world")]),
	],
}

json = document.to_json()
```

`Pandoc.to_json(document)` is an explicit equivalent. `Block`, `Inline`, `MetaValue`, `Attr`, and list-attribute values also provide `.to_json()`.

## Supported AST

- Metadata: maps, lists, booleans, strings, inlines, and blocks
- Blocks: plain, paragraph, line block, code block, ordered list, and header
- Inlines: text, emphasis, underline, strong, strikeout, superscript, subscript, small caps, space, soft break, and line break
- Attributes and ordered-list styles/delimiters

The emitted document uses Pandoc API version `1.23.1`, matching the existing fixtures. Unsupported constructors are absent from the closed nominal unions, so missing support is caught by the type checker rather than producing placeholder JSON.

## Development

Run `./run-tests.sh`. Pandoc itself is not required: golden tests exercise exact JSON output, including string escaping.

## License

[UPL-1.0](LICENSE)
