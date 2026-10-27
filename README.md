# roc-pandoc

A Roc package for building type-safe [Pandoc](https://pandoc.org/) documents. It covers Pandoc's JSON AST at API version `1.23.1` and provides two complementary interfaces:

- `Author` is the concise default for headings, paragraphs, formatting, links, images, lists, quotations, spans, and divisions.
- `Pandoc` exposes the complete AST when you need metadata, attributes, citations, raw content, tables, figures, notes, or exact Pandoc structure.

Both layers produce the same `Pandoc.Document`, `Pandoc.Block`, and `Pandoc.Inline` types, so an application can start with `Author` and use advanced constructors only where needed. String values, metadata keys, identifiers, classes, and attribute pairs are escaped by Roc's built-in `Json` encoder.

## Quick start

Add the package to an app header and import its authoring interface:

```roc
app [main!] {
	pandoc: "../package/main.roc",
}

import pandoc.Author
```

Released applications should replace the local path with the package's release URL.

```roc
document = Author.document([
	Author.heading(1, "Hello"),
	Author.paragraph_inlines([
		Author.text("Generated with "),
		Author.strong("Roc"),
		Author.text("."),
	]),
])
```

Use `pandoc.Pandoc` alongside `Author` when a document needs lower-level structure:

```roc
import pandoc.Author
import pandoc.Pandoc

document = Author.document([
	Author.heading(1, "Release notes"),
	Pandoc.Block.HorizontalRule,
	Pandoc.Block.Para([
		Pandoc.Inline.Math(Pandoc.MathType.InlineMath, "E = mc^2"),
	]),
])
	|> Author.with_meta(
		Dict.empty()
			|> Dict.insert("title", Pandoc.MetaValue.String("Release notes")),
	)
```

Encode the resulting document through Roc's statically dispatched JSON encoder, then pass that JSON to a local `pandoc` executable:

```roc
json = Json.to_str(document)
```

The workflow examples below contain complete applications that write an intermediate JSON file and produce a useful output artifact beside `main.roc`.

## API layers

`Author` deliberately supplies common defaults: empty attributes and titles, plain-text convenience arguments, ordered lists starting at one with Pandoc's default marker style, and documents with initially empty metadata. Its heading level and list contents are not validated. Use `Pandoc` when those defaults hide information you need—for example, a link title, CSS classes, a non-default list marker, formatted image descriptions, or a table cell span.

The advanced `Pandoc` API represents the complete AST supported by Pandoc JSON API `1.23.1`:

- Metadata: maps, lists, booleans, strings, inlines, and blocks.
- Blocks: plain, paragraph, line block, code block, raw block, block quote, ordered list, bullet list, definition list, header, horizontal rule, table, figure, and division.
- Inlines: string, emphasis, underline, strong, strikeout, superscript, subscript, small caps, quoted text, citation, code, space, soft break, line break, math, raw inline, link, image, note, and span.
- Supporting structures: attributes, targets, quote and math types, citations, captions, table column specifications, heads, bodies, feet, rows and cells, plus ordered-list styles and delimiters.

Closed tag unions make unsupported or misspelled constructors a type error instead of silently emitting placeholder JSON. The package constant `Pandoc.api_version` records the schema version emitted by the encoder.

## Example gallery

Run each workflow from its own directory so its relative output paths resolve beside `main.roc`. The workflow examples require `pandoc` on `PATH` and leave both the rendered artifact and its `.pandoc.json` input in that directory.

| Workflow | Command | Result |
| --- | --- | --- |
| Web page | `cd examples/web-page && roc main.roc` | Standalone HTML product page |
| Office report | `cd examples/office-report && roc main.roc` | Editable DOCX quarterly report |
| Slide deck | `cd examples/slide-deck && roc main.roc` | Editable PowerPoint presentation |
| Ebook | `cd examples/ebook && roc main.roc` | EPUB 3 book with metadata and contents |
| Technical paper | `cd examples/technical-paper && roc main.roc` | LaTeX source, with a documented PDF variant |
| Research summary | `cd examples/research-summary && roc main.roc` | HTML with citations and a comparison table |

The hello-world example prints Pandoc JSON. The CSV reading-list and Markdown examples render HTML without opening a viewer; pass `--open` to open it. An optional input string can still be supplied. Each release includes all nine examples and their expected output in its examples ZIP.

## Development

Install Blueprint 0.8.0, Pandoc, unzip, and the latest Roc nightly, then run:

```sh
blueprint check
blueprint run check
blueprint run goldens -- --update
blueprint run release-package -- test-examples
```

Blueprint locks the tooling compiler separately; the package compiler is the host's latest nightly. The shared release workflow builds and tests the exact bundle and examples archive before publication. Repository examples follow the working tree; archived examples name the immutable release bundle.

Generate the public API reference for both exposed modules with the package root:

```sh
roc docs package/main.roc
```

The generated site is written to `generated-docs` by default. Add `--serve` to browse it locally.

## License

[UPL-1.0](LICENSE)
