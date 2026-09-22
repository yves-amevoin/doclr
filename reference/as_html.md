# Render a converted document as HTML

Render a converted document as HTML

## Usage

``` r
as_html(x, ...)
```

## Arguments

- x:

  A
  [doclr_document](https://yves-amevoin.github.io/doclr/reference/doclr_document.md).

- ...:

  Unused, for extensibility.

## Value

A single string of HTML.

## Examples

``` r
if (FALSE) {
as_html(doclr_convert("report.pdf", doclr_options(to_formats = "html")))
}
```
