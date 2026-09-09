app [main!] {
	pandoc: "../package/main.roc",
	parser: "https://github.com/lukewilliamboswell/roc-parser/releases/download/1.2.0/GzeZxk7V7GHFa42qhgzd8gUgX6cEyY3NmrwmDfsuskNd.tar.zst",
}

import pandoc.Pandoc
import parser.CSV
import parser.Parser

input =
	\\Programming in the 21st Century,Richard Feldman,2024
	\\Out of the Tar Pit,Ben Moseley and Peter Marks,2006
	\\The Essence of Functional Programming,Philip Wadler,1992

Book : { title : Str, author : Str, year : U64 }

book_parser : Parser.Parser(CSV.CSVRecord, Book)
book_parser =
	CSV.record(|title| |author| |year| { title, author, year })
		.keep(CSV.field(CSV.string))
		.keep(CSV.field(CSV.string))
		.keep(CSV.field(CSV.u64))

main! = |args| {
	csv_input = args.get(0) ?? input
	document =
		match CSV.parse_str(book_parser, csv_input) {
			Ok(books) => reading_list(books)
			Err(_) => Pandoc.Document.{ meta: Dict.empty(), blocks: [Pandoc.Block.Para([Pandoc.Inline.String("Invalid reading list")])] }
		}

	echo!(document.to_json())
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
