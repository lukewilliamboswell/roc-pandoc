module [
    Pandoc,
    encode,
]

Pandoc : {
    blocks : List Block,
    meta : Dict Str MetaValue,
}

encode : Pandoc -> Str
encode = \pandoc ->

    blocksStr = pandoc.blocks |> List.map encodeBlock |> Str.joinWith ","
    metaStr = pandoc.meta |> encodeMetaValueDict

    """
    {"pandoc-api-version":[1,23,1],"meta":$(metaStr),"blocks":[$(blocksStr)]}
    """

MetaValue : [
    MetaMap (Dict Str MetaValue),
    MetaList (List MetaValue),
    MetaBool Bool,
    MetaString Str,
    MetaInlines (List Inline),
    MetaBlocks (List Block),
]

encodeMetaValueDict : Dict Str MetaValue -> Str
encodeMetaValueDict = \map ->
    if Dict.isEmpty map then
        "{}"
    else
        map
        |> Dict.toList
        |> List.map \(key, value) ->
            """
            "$(key)":$(encodeMetaValue value)
            """
        |> Str.joinWith ","
        |> \str ->"{$(str)}"

encodeMetaValue : MetaValue -> Str
encodeMetaValue = \mv ->
    when mv is
        MetaMap map ->
            encodeMetaValueDict map

        MetaList list ->
            metaList = list |> List.map encodeMetaValue |> Str.joinWith ","
            """
            {"t":"MetaList","c":[$(metaList)]}
            """

        MetaBool bool ->
            if bool then
                """
                {"t":"MetaBool","c":true}
                """
            else
                """
                {"t":"MetaBool","c":false}
                """

        MetaString str ->
            """
            {"t":"MetaString","c":"$(str)"}
            """

        MetaInlines inlines ->
            inlineStr = inlines |> List.map encodeInline |> Str.joinWith ","
            """
            {"t":"MetaInlines","c":[$(inlineStr)]}
            """

        MetaBlocks blocks ->
            metaBlocks = blocks |> List.map encodeBlock |> Str.joinWith ","
            """
            {"t":"MetaBlocks","c":[$(metaBlocks)]}
            """

Block : [
    Plain (List Inline),
    Para (List Inline),
    LineBlock (List (List Inline)),
    CodeBlock Attr Str,
    #RawBlock Format Str,
    #BlockQuote (List Block),
    OrderedList ListAttributes (List (List Block)),
    #BulletList (List (List Block)),
    #DefinitionList (List (List Inline, List Block)),
    Header I32 Attr (List Inline),
    #HorizontalRule,
    #Table,
    #Figure Attr Caption (List Block),
    #Div Attr (List Block),
    #Null,
]

encodeBlock : Block -> Str
encodeBlock = \block ->
    when block is
        Plain inlines ->
            """
            {"t":"Plain","c":[$(encodeInlineList inlines)]}
            """

        Para inlines ->
            """
            {"t":"Para","c":[$(encodeInlineList inlines)]}
            """

        LineBlock lines ->
            lines
            |> List.map \inlines ->
                """
                [$(encodeInlineList inlines)]
                """
            |> Str.joinWith ","
            |> \str ->
                """
                {"t":"LineBlock","c":[$(str)]}
                """

        CodeBlock attrs contents ->
            """
            {"t":"CodeBlock","c":[$(encodeAttr attrs),"$(contents)"]}
            """

        #RawBlock _ _ -> "TODO"
        #BlockQuote _ -> "TODO"
        OrderedList listAttrs listBlockList ->

            encodeBlockList : List Block, List Str -> List Str
            encodeBlockList = \blocks, acc ->
                when blocks is
                    [] -> acc
                    [first, .. as rest] -> encodeBlockList rest (List.append acc (encodeBlock first))

            lblStr : Str
            lblStr =
                listBlockList
                |> List.map \blocks ->
                    blocks
                    |> encodeBlockList  []
                    |> Str.joinWith ","
                    |> \str -> "[$(str)]"
                |> Str.joinWith ","

            "{\"t\":\"OrderedList\",\"c\":[$(encodeListAttributes listAttrs),[$(lblStr)]]}"

        #BulletList _ -> "TODO"
        #DefinitionList _ -> "TODO"
        Header level attrs inlines ->
            """
            {"t":"Header","c":[$(Num.toStr level),$(encodeAttr attrs),[$(encodeInlineList inlines)]]}
            """

        #HorizontalRule -> "TODO"
        #Table -> "TODO"
        #Figure _ _ _ -> "TODO"
        #Div _ _ -> "TODO"
        #Null -> "TODO"

Inline : [

    # Text
    String Str,

    # Emphasized text
    Emph (List Inline),

    # Underlined text
    Underline (List Inline),

    # Strongly emphasized text
    Strong (List Inline),

    # Strikeout text
    Strikeout (List Inline),

    # Superscripted text
    Superscript (List Inline),

    # Subscripted text
    Subscript (List Inline),

    # Small caps text
    SmallCaps (List Inline),

    ## Quoted text
    #Quoted QuoteType (List Inline),

    ## Citation
    #Cite (List Citation) (List Inline),

    ## Inline code
    #Code Attr Str,

    # Inter-word space
    Space,

    # Soft line break
    SoftBreak,

    # Hard line break
    LineBreak,

    ## TeX math
    #Math MathType Str,

    ## Raw inline
    #RawInline Format Str,

    ## Hyperlink: alt text (list of inlines), target
    #Link Attr (List Inline) Target,

    ## Image: alt text (list of inlines), target
    #Image Attr (List Inline) Target,

    ## Footnote or endnote
    #Note (List Block),

    ## Generic inline container with attributes
    #Span Attr (List Inline),
]

#Format : {}

ListAttributes : {
    start : I32,
    style : [
        DefaultStyle,
        Example,
        Decimal,
        LowerRoman,
        UpperRoman,
        LowerAlpha,
        UpperAlpha,
    ],
    delim : [
        DefaultDelim,
        Period,
        OneParen,
        TwoParens,
    ],
}

encodeListAttributes : ListAttributes -> Str
encodeListAttributes = \{start, style, delim} ->

    styleStr =
        when style is
            DefaultStyle -> "{\"t\":\"DefaultStyle\"}"
            Example -> "{\"t\":\"Example\"}"
            Decimal -> "{\"t\":\"Decimal\"}"
            LowerRoman -> "{\"t\":\"LowerRoman\"}"
            UpperRoman -> "{\"t\":\"UpperRoman\"}"
            LowerAlpha -> "{\"t\":\"LowerAlpha\"}"
            UpperAlpha -> "{\"t\":\"UpperAlpha\"}"

    delimStr =
        when delim is
            DefaultDelim -> "{\"t\":\"DefaultDelim\"}"
            Period -> "{\"t\":\"Period\"}"
            OneParen -> "{\"t\":\"OneParen\"}"
            TwoParens -> "{\"t\":\"TwoParens\"}"

    "[$(Num.toStr start),$(styleStr),$(delimStr)]"

#Caption : {}
#QuoteType : {}
#Citation : {}
#MathType : {}
#Target : {}

encodeInline : Inline -> Str
encodeInline = \inline ->
    when inline is

        # Text
        String str ->
            """
            {"t":"Str","c":"$(str)"}
            """

        # Emphasized text
        Emph inlines ->
            """
            {"t":"Emph","c":[$(encodeInlineList inlines)]}
            """

        # Underlined text
        Underline inlines ->
            """
            {"t":"Underline","c":[$(encodeInlineList inlines)]}
            """

        # Strongly emphasized text
        Strong inlines ->
            """
            {"t":"Strong","c":[$(encodeInlineList inlines)]}
            """

        # Strikeout text
        Strikeout inlines ->
            """
            {"t":"Strikeout","c":[$(encodeInlineList inlines)]}
            """

        # Superscripted text
        Superscript inlines ->
            """
            {"t":"Superscript","c":[$(encodeInlineList inlines)]}
            """

        # Subscripted text
        Subscript inlines ->
            """
            {"t":"Subscript","c":[$(encodeInlineList inlines)]}
            """

        # Small caps text
        SmallCaps inlines ->
            """
            {"t":"SmallCaps","c":[$(encodeInlineList inlines)]}
            """

        ## Quoted text
        #Quoted _ _ -> "TODO"

        ## Citation
        #Cite _ _ -> "TODO"

        ## Inline code
        #Code _ _ -> "TODO"

        # Inter-word space
        Space ->
            """
            {"t":"Space"}
            """

        # Soft line break
        SoftBreak ->
            """
            {"t":"SoftBreak"}
            """

        # Hard line break
        LineBreak ->
            """
            {"t":"LineBreak"}
            """

        ## TeX math
        #Math _ _ -> "TODO"

        ## Raw inline
        #RawInline _ _ -> "TODO"

        ## Hyperlink: alt text (list of inlines), target
        #Link _ _ _ -> "TODO"

        ## Image: alt text (list of inlines), target
        #Image attr inlines target -> "TODO"

        ## Footnote or endnote
        #Note blocks -> "TODO"

        ## Generic inline container with attributes
        #Span attr inlines -> "TODO"

expect
    String "foo"
    |> encodeInline
    ==
    """
    {"t":"Str","c":"foo"}
    """

expect
    Space
    |> encodeInline
    ==
    """
    {"t":"Space"}
    """

encodeInlineList : List Inline -> Str
encodeInlineList = \inlines -> inlines |> List.map encodeInline |> Str.joinWith ","

Attr : {
    identifier : Str,
    classes : List Str,
    attributes : List (Str, Str),
}

encodeAttr : Attr -> Str
encodeAttr = \{ identifier, classes, attributes } ->

    classesStr =
        classes
        |> List.map \class ->
            """
            "$(class)"
            """
        |> Str.joinWith ","

    attributesStr =
        attributes
        |> List.map \(key, value) ->
            """
            ["$(key)","$(value)"]
            """
        |> Str.joinWith ","

    """
    ["$(identifier)",[$(classesStr)],[$(attributesStr)]]
    """

expect
    Header 1 { identifier: "a", classes: ["b"], attributes: [("c", "d")] } [String "foo", Space, String "bar!"]
    |> encodeBlock
    ==
    """
    {"t":"Header","c":[1,["a",["b"],[["c","d"]]],[{"t":"Str","c":"foo"},{"t":"Space"},{"t":"Str","c":"bar!"}]]}
    """
