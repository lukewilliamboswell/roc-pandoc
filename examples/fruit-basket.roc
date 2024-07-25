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
            Header 1 {identifier: "special", classes: ["bold"], attributes: [("aria-label","heading")]} [String "Fruit", Space, String "Basket"],
            Plain [String "Some", Space, String "text..."],
            Para [String "TODO", Space, String "add more content here."],
            LineBlock [
                [String "This", Space, String "is", Space, String "a", Space, String "line", Space, String "block."],
                [String "It", Space, String "has", Space, String "some", Space, String "text."],
            ]
        ],
    }

    Stdout.write! (Pandoc.encode doc)
