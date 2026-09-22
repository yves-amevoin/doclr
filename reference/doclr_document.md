# A converted docling document

The object returned by
[`doclr_convert()`](https://yves-amevoin.github.io/doclr/reference/doclr_convert.md)
and friends. It holds whichever representations the server produced —
controlled by the `to_formats` argument of
[`doclr_options()`](https://yves-amevoin.github.io/doclr/reference/doclr_options.md)
— plus the conversion status and any errors the server reported. Pull
content out with
[`as_markdown()`](https://yves-amevoin.github.io/doclr/reference/as_markdown.md),
[`as_text()`](https://yves-amevoin.github.io/doclr/reference/as_text.md),
[`as_html()`](https://yves-amevoin.github.io/doclr/reference/as_html.md),
[`as_json()`](https://yves-amevoin.github.io/doclr/reference/as_json.md)
or
[`as_doctags()`](https://yves-amevoin.github.io/doclr/reference/as_doctags.md).
