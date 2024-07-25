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
        meta: Dict.empty {} |> Dict.insert "isBasic" (MetaBool Bool.true),
        blocks: [
            Header 1 { identifier: "first", classes: [], attributes: [] } [String "Hello"],
            Para [String "world"],
        ],
    }

    Stdout.write! (Pandoc.encode doc)
