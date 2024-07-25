app [main] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.12.0/Lb8EgiejTUzbggO2HVVuPJFkwvvsfW6LojkLR20kTVE.tar.br",
    pandoc: "../package/main.roc",
}

import cli.Stdout
import cli.Task exposing [Task]
import pandoc.Pandoc

main : Task {} _
main =

    doc = {
        meta: Dict.empty {},
        blocks: [
            Plain [
                String "Text",
                SoftBreak,
                Emph [String "Emphasized"],
                SoftBreak,
                Underline [String "Underlined text"],
                SoftBreak,
                Strong [String "Strongly emphasized text"],
                ],
            Para [
                SoftBreak,
                Strikeout [String "Strikeout text"],
                SoftBreak,
                Superscript [String "Superscripted text"],
                SoftBreak,
                Subscript [String "Subscripted text"],
                SoftBreak,
                SmallCaps [String "Small caps text"],
                SoftBreak,
            ],
        ],
    }

    Stdout.write! (Pandoc.encode doc)
