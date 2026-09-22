# Convert a document, waiting for the result

The function most users want. Submits the source asynchronously, shows a
`cli` spinner while the server works, and returns the finished document.
URLs are sent to the source endpoint and everything else is uploaded, so
a mixed vector of URLs and paths is handled in one call.

## Usage

``` r
doclr_convert(
  source,
  options = doclr_options(),
  client = doclr_client(),
  poll_interval = 2,
  timeout = 600,
  quiet = !interactive()
)
```

## Arguments

- source:

  One or more document URLs or local file paths.

- options:

  A
  [`doclr_options()`](https://yves-amevoin.github.io/doclr/reference/doclr_options.md)
  object.

- client:

  A
  [`doclr_client()`](https://yves-amevoin.github.io/doclr/reference/doclr_client.md).

- poll_interval:

  Seconds between status checks.

- timeout:

  Give up after this many seconds.

- quiet:

  Suppress the progress spinner.

## Value

A
[doclr_document](https://yves-amevoin.github.io/doclr/reference/doclr_document.md)
object, or a list of them when several sources were converted.

## Examples

``` r
if (FALSE) {
doc <- doclr_convert("https://arxiv.org/pdf/2408.09869")
as_markdown(doc)
}
```
