app [main!] { pandoc: "../../package/main.roc", roc: "nightly-2026-09-08-39a3f89" }

import pandoc.Author

main! = |_args| {
	document = Author.document([
		Author.heading(1, "Hello"),
		Author.paragraph_inlines([Author.text("Read "), Author.link("Roc", "https://roc-lang.org")]),
		Author.bullet_list([[Author.paragraph("one")], [Author.paragraph("two")]]),
	])
	echo!(document.to_json())
	Ok({})
}
