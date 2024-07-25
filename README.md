# roc-pandoc

A [roc](https://www.roc-lang.org) package for generating [pandoc](https://pandoc.org) documents.

This package provides the pandoc AST primitives encoding to JSON.

```
+-----+     +------+     +-------+
| ROC |---->| JSON |---->| PANDOC|
+-----+     +------+     +-------+
```

**Status** Work In Progress 🚧

- [x] Document metadata
- [ ] Blocks
  - [x] Plain text, not a paragraph
  - [x] Paragraph
  - [x] Multiple non-breaking lines
  - [x] Code block (literal) with attributes
  - [ ] Raw block
  - [ ] Block quote
  - [x] Ordered list (attributes and a list of items, each a list of blocks)
  - [ ] Bullet list (list of items, each a list of blocks)
  - [ ] Definition list. Each list item is a pair consisting of a term (a list of inlines) and one or more definitions (each a list of blocks)
  - [x] Header - level (integer) and text (inlines)
  - [ ] Horizontal rule
  - [ ] Table
  - [ ] Figure
  - [ ] Generic block container with attributes
  - [ ] Nothing
- [ ] Inlines
  - [x] Text
  - [x] Emphasized text
  - [x] Underlined text
  - [x] Strongly emphasized text
  - [x] Strikeout text
  - [x] Superscripted text
  - [x] Subscripted text
  - [x] Small caps text
  - [ ] Quoted text
  - [ ] Citation
  - [ ] Inline code
  - [x] Inter-word space
  - [x] Soft line break
  - [x] Hard line break
  - [ ] TeX math
  - [ ] Raw inline
  - [ ] Hyperlink: alt text (list of inlines), target
  - [ ] Image: alt text (list of inlines), target
  - [ ] Footnote or endnote
  - [ ] Generic inline container with attributes

## Example

- `$ roc examples/hello-world.roc`
```json
{
  "pandoc-api-version": [1, 23, 1],
  "meta": { "isBasic": { "t": "MetaBool", "c": true } },
  "blocks": [
    {
      "t": "Header",
      "c": [1, ["first", [], []], [{ "t": "Str", "c": "Hello" }]]
    },
    { "t": "Para", "c": [{ "t": "Str", "c": "world" }] }
  ]
}

```

- `$ roc examples/hello-world.roc | pandoc -f json -t markdown`
```md
# Hello {#first}

world
```

- `$ roc examples/hello-world.roc | pandoc -f json -t html`
```html
<h1 id="first">Hello</h1>
<p>world</p>
```
