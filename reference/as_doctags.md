# Render a converted document as DocTags

Render a converted document as DocTags

## Usage

``` r
as_doctags(x, ...)
```

## Arguments

- x:

  A
  [doclr_document](https://yves-amevoin.github.io/doclr/reference/doclr_document.md).

- ...:

  Unused, for extensibility.

## Value

A single string of DocTags markup.

## Examples

``` r
if (FALSE) {
as_doctags(doclr_convert("report.pdf", doclr_options(to_formats = "doctags")))
}
```
