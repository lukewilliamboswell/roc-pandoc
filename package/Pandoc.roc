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
    {
      "pandoc-api-version": [1, 23, 1],
      "meta": $(metaStr),
      "blocks": [$(blocksStr)]
    }
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
            {"$(key)":$(encodeMetaValue value)}
            """
        |> Str.joinWith ","

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
                { "t": "MetaBool", "c": true }
                """
            else
                """
                { "t": "MetaBool", "c": false }
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
]

encodeBlock : Block -> Str
encodeBlock = \block ->
    when block is
        Plain inlines ->
            inlines
            |> List.map encodeInline
            |> Str.joinWith ","
            |> \c ->
                """
                {"t":"Plain","c":[$(c)]}
                """

Inline : [
    String Str,
    Space,
]

encodeInline : Inline -> Str
encodeInline = \inline ->
    when inline is
        String str ->
            """
            {"t":"Str","c":"$(str)"}
            """

        Space ->
            """
            {"t":"Space"}
            """
