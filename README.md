# roc-pandoc

A [roc](https://www.roc-lang.org) package for generating [pandoc](https://pandoc.org) documents.

This package provides the pandoc AST primitives and a function to encode as JSON.

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
