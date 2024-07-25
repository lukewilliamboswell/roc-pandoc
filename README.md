# roc-pandoc

A [roc](https://www.roc-lang.org) package for generating [pandoc](https://pandoc.org) documents.

This package provides the pandoc AST primitives and a function to encode as JSON.

Please let me know if you found this helpful. Please open an issue if you have any questions or suggestions.

## Examples

- `$ roc examples/hello-world.roc`
```
{
  "pandoc-api-version": [1, 23, 1],
  "meta": {},
  "blocks": [{"t":"Plain","c":[{"t":"Str","c":"Hello"},{"t":"Space"},{"t":"Str","c":"world!"}]}]
}
```

- `$ roc examples/kitchen-sink.roc | pandoc -f json -t markdown`
```md
Text *Emphasized* [Underlined text]{.underline}
**Strongly emphasized text**

~~Strikeout text~~ ^Superscripted text^ ~Subscripted text~
[Small caps text]{.smallcaps}
```

- `$ roc examples/kitchen-sink.roc | pandoc -f json -t html`
```html
Text <em>Emphasized</em> <u>Underlined text</u> <strong>Strongly
emphasized text</strong>
<p> <del>Strikeout text</del> <sup>Superscripted text</sup>
<sub>Subscripted text</sub> <span class="smallcaps">Small caps
text</span> </p>
```
