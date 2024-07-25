app [main] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.12.0/Lb8EgiejTUzbggO2HVVuPJFkwvvsfW6LojkLR20kTVE.tar.br",
    pandoc: "../package/main.roc",
}

import cli.Stdout
import cli.Task
import pandoc.Pandoc

main =
    {
        meta: Dict.empty {},
        blocks: [
            OrderedList
                {
                    start: 1,
                    style: Decimal,
                    delim: Period,
                }
                [
                    [Plain [String "one"]],
                    [Plain [String "two"]],
                    [Plain [String "three"]],
                ],
        ],
    }
        |> Pandoc.encode
        |> Stdout.write!
