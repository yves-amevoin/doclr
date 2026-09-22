# Convert documents by uploading local files

Calls `POST /v1/convert/file`, which blocks until the conversion
finishes.

## Usage

``` r
doclr_convert_file(paths, options = doclr_options(), client = doclr_client())
```

## Arguments

- paths:

  Character vector of local file paths.

- options:

  A
  [`doclr_options()`](https://yves-amevoin.github.io/doclr/reference/doclr_options.md)
  object.

- client:

  A
  [`doclr_client()`](https://yves-amevoin.github.io/doclr/reference/doclr_client.md).

## Value

A
[doclr_document](https://yves-amevoin.github.io/doclr/reference/doclr_document.md)
object, or a list of them when several files were converted.

## Examples

``` r
if (FALSE) {
doclr_convert_file("report.pdf")
}
```
