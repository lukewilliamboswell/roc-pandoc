app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-26-d6267b4" }

import pandoc.Author

main! = |_args| {
	document = Author.titled_document(
		"Builder showcase",
		[
			Author.h1("Hello"),
			Author.h2("Links"),
			Author.paragraph_inlines([Author.text("Read "), Author.link("Roc", "https://roc-lang.org")]),
			Author.h3("Lists"),
			Author.bullet_list_text(["one", "two"]),
			Author.ordered_list_text(["first", "second"]),
			Author.code_block_language("roc", "answer = 42"),
		],
	)
	echo!(Json.to_str(document))
	Ok({})
}
