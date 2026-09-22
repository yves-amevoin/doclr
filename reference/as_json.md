# Extract the structured JSON representation of a document

Returns the docling JSON tree, which is where tables, figures and
reading order live.

## Usage

``` r
as_json(x, simplify = FALSE, ...)
```

## Arguments

- x:

  A
  [doclr_document](https://yves-amevoin.github.io/doclr/reference/doclr_document.md).

- simplify:

  Passed to
  [`jsonlite::fromJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)
  when the server sent the JSON as a string. Set `FALSE` to keep a
  faithful nested list.

- ...:

  Unused, for extensibility.

## Value

A named list.

## Examples

``` r
if (FALSE) {
json <- as_json(doclr_convert("report.pdf", doclr_options(to_formats = "json")))
names(json)
}
```
