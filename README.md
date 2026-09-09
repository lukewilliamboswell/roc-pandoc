# roc-pandoc

A Roc package for constructing Pandoc documents and encoding them to Pandoc's JSON AST format. Use it to generate input for Pandoc without assembling untyped JSON by hand.

The package uses nominal types with statically dispatched associated methods. String values and dictionary keys are escaped by Roc's built-in `Json` encoder.

## Quick start

Add the package to an app header and import its `Pandoc` module:

```roc
app [main!] {
	pandoc: "../package/main.roc",
}

import pandoc.Pandoc
```

Released applications should replace the local path with the package's release URL. Construct a document from nominal AST values and encode it with static dispatch:

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

The resulting string can be printed with the built-in `echo!` platform and redirected to a file:

```sh
roc examples/hello-world.roc > document.json
pandoc --from=json --to=html document.json
```

## Supported AST

- Metadata: maps, lists, booleans, strings, inlines, and blocks
- Blocks: plain, paragraph, line block, code block, ordered list, and header
- Inlines: text, emphasis, underline, strong, strikeout, superscript, subscript, small caps, space, soft break, and line break
- Attributes and ordered-list styles/delimiters

Unsupported constructors are absent from the closed nominal unions, so missing support is caught by the type checker rather than producing placeholder JSON.

## Development

Run the cross-platform golden test driver from the repository root:

```sh
python scripts/all_tests.py
```

The full driver checks formatting, package and example compilation, golden output, generated API documentation, and whether Pandoc accepts every generated AST. The golden runner executes the Roc test applications in parallel, compares their stdout with the JSON files in `tests/goldens`, then round-trips each document through `pandoc --from=json --to=json`. To regenerate the checked-in outputs after an intentional change:

```sh
python scripts/test.py --update
git diff -- tests/goldens
```

The examples include a basic document, a CSV reading list of work that influenced Roc, and Markdown conversion. The parser-backed examples use [`roc-parser`](https://github.com/lukewilliamboswell/roc-parser). They use [`basic-cli`](https://github.com/roc-lang/basic-cli) to check for a local `pandoc`, render standalone HTML, and open the result using the operating system's available opener:

```sh
roc examples/csv-reading-list.roc
```

The reading-list choices reflect Roc's documented lineage and implementation: Roc is a [direct descendant of Elm](https://www.roc-lang.org/faq), and its opportunistic mutation is based on [Perceus](https://www.microsoft.com/en-us/research/wp-content/uploads/2020/11/perceus-tr-v4.pdf).

Generate the public API reference with:

```sh
roc docs package/Pandoc.roc
```

## License

[UPL-1.0](LICENSE)
