# Render a converted document as plain text

Render a converted document as plain text

## Usage

``` r
as_text(x, ...)
```

## Arguments

- x:

  A
  [doclr_document](https://yves-amevoin.github.io/doclr/reference/doclr_document.md).

- ...:

  Unused, for extensibility.

## Value

A single string of plain text.

## Examples

``` r
if (FALSE) {
as_text(doclr_convert("report.pdf", doclr_options(to_formats = "text")))
}
```
