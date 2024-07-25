# roc-pandoc

A [roc](https://www.roc-lang.org) package for generating [pandoc](https://pandoc.org) documents, by enocding to the JSON AST

## Running an example

```
$ roc examples/hello-world.roc | pandoc -f json -t html
Hello world!
```
