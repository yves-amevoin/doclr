# Convert documents given by URL

Calls `POST /v1/convert/source`, which blocks until the conversion
finishes. Use
[`doclr_convert()`](https://yves-amevoin.github.io/doclr/reference/doclr_convert.md)
for anything long enough that you would rather poll.

## Usage

``` r
doclr_convert_source(urls, options = doclr_options(), client = doclr_client())
```

## Arguments

- urls:

  Character vector of document URLs.

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
object, or a list of them when several sources were converted.

## Examples

``` r
if (FALSE) {
doclr_convert_source("https://arxiv.org/pdf/2408.09869")
}
```
