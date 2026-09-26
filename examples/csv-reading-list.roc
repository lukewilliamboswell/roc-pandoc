app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0-rc1/3hT3SoHZ6qbEsa9qVFLUW3547U5LeoNd1KbpqLpz4r1i.tar.zst",
	pandoc: "https://github.com/lukewilliamboswell/roc-pandoc/releases/download/0.1.0/8pDy8BV37fo72fRdpLr6rsAcosdJKJgVR2mT9GU17FuD.tar.zst",
	parser: "https://github.com/lukewilliamboswell/roc-parser/releases/download/1.2.0/GzeZxk7V7GHFa42qhgzd8gUgX6cEyY3NmrwmDfsuskNd.tar.zst",
	roc: "nightly-2026-09-26-d6267b4",
}

import pandoc.Pandoc
import parser.CSV
import parser.Parser
import cli.OsStr
import Render

input =
	\\Elm: Concurrent FRP for Functional GUIs,Evan Czaplicki,2012
	\\Koka: Programming with Row Polymorphic Effect Types,Daan Leijen,2014
	\\Perceus: Garbage Free Reference Counting with Reuse,Sebastian Reinking and Ningning Xie and Leonardo de Moura and Daan Leijen,2021
	\\Tail Modulo Cons,Frédéric Bour and Basile Clément and Gabriel Scherer,2021
	\\Compiling Pattern Matching to Good Decision Trees,Luc Maranget,2008

Book : { title : Str, author : Str, year : U64 }

book_parser : Parser.Parser(CSV.CSVRecord, Book)
book_parser =
	CSV.record(|title| |author| |year| { title, author, year })
		.keep(CSV.field(CSV.string))
		.keep(CSV.field(CSV.string))
		.keep(CSV.field(CSV.u64))

main! : List(OsStr) => Try({}, _)
main! = |args| {
	csv_input = args.get(1).map_ok(OsStr.display) ?? input
	document =
		match CSV.parse_str(book_parser, csv_input) {
			Ok(books) => reading_list(books)
			Err(problem) => Pandoc.Document.{ meta: Dict.empty(), blocks: [Pandoc.Block.Para([Pandoc.Inline.String("Invalid reading list: ${Str.inspect(problem)}")])] }
		}

	Render.html_and_open!("roc-influences", Json.to_str(document))?
	Ok({})
}

reading_list : List(Book) -> Pandoc.Document
reading_list = |books| Pandoc.Document.{
	meta: Dict.empty()
		|> Dict.insert("title", Pandoc.MetaValue.Inlines([Pandoc.Inline.String("Functional programming reading list")]))
		|> Dict.insert("generated", Pandoc.MetaValue.Bool(True)),
	blocks: [
		Pandoc.Block.Header(1, Pandoc.Attr.{ identifier: "reading-list", classes: ["catalogue"], attributes: [("data-source", "books.csv")] }, [Pandoc.Inline.String("Reading list")]),
		Pandoc.Block.OrderedList(
			Pandoc.ListAttributes.{ start: 1, style: Pandoc.ListStyle.Decimal, delimiter: Pandoc.ListDelimiter.Period },
			books.map(book_item),
		),
	],
}

book_item : Book -> List(Pandoc.Block)
book_item = |book| [
	Pandoc.Block.Plain([
		Pandoc.Inline.Strong([Pandoc.Inline.String(book.title)]),
		Pandoc.Inline.Space,
		Pandoc.Inline.Emph([Pandoc.Inline.String("by ${book.author}")]),
		Pandoc.Inline.Space,
		Pandoc.Inline.String("(${book.year.to_str()})"),
	]),
]
