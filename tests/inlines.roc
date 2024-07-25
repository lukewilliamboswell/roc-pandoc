app [main] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.12.0/Lb8EgiejTUzbggO2HVVuPJFkwvvsfW6LojkLR20kTVE.tar.br",
    pandoc: "../package/main.roc",
}

import cli.Stdout
import cli.Task
import pandoc.Pandoc

main =
    blocks = [
        Para [
            String "text",
            SoftBreak,
            Emph [String "emphasized"],
        ],
        Para [
            Underline [String "underlined"],
            SoftBreak,
            Strong [String "strong"],
        ],
        Para [
            Strikeout [String "strikeout"],
            SoftBreak,
            Superscript [String "superscripted"],
        ],
        Para [
            Subscript [String "subscripted"],
            SoftBreak,
            SmallCaps [String "smallcaps"],
        ],
    ]

    {
        meta: Dict.empty {},
        blocks,
    }
        |> Pandoc.encode
        |> Stdout.write!
