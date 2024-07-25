app [main] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.12.0/Lb8EgiejTUzbggO2HVVuPJFkwvvsfW6LojkLR20kTVE.tar.br",
    pandoc: "../package/main.roc",
}

import cli.Stdout
import cli.Task
import pandoc.Pandoc

main =

    firstHeader =
        Header
            1
            {
                identifier: "first",
                classes: [],
                attributes: [],
            }
            [String "First"]

    secondHeader =
        Header
            2
            {
                identifier: "second",
                classes: [],
                attributes: [],
            }
            [String "Second"]

    blocks = [
        firstHeader,
        secondHeader,
    ]

    {
        meta: Dict.empty {},
        blocks,
    }
        |> Pandoc.encode
        |> Stdout.write!
