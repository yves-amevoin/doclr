# Create a connection to a docling-serve server

Builds a lightweight handle holding the base URL, credentials and
request policy used by every other function in the package. Nothing is
sent to the server until you call
[`doclr_health()`](https://yves-amevoin.github.io/doclr/reference/doclr_health.md)
or one of the convert functions.

## Usage

``` r
doclr_client(
  url = Sys.getenv("DOCLING_SERVE_URL", DOCLR_DEFAULT_URL),
  api_key = Sys.getenv("DOCLING_SERVE_API_KEY"),
  timeout = 300,
  max_tries = 3
)
```

## Arguments

- url:

  Base URL of the docling-serve server. Defaults to the
  `DOCLING_SERVE_URL` environment variable, falling back to
  `"http://localhost:5001"`.

- api_key:

  API key sent as an `X-Api-Key` header. Defaults to the
  `DOCLING_SERVE_API_KEY` environment variable; `NULL` or `""` means no
  authentication, which is the usual case for a local server.

- timeout:

  Request timeout in seconds.

- max_tries:

  Number of attempts for transient failures, passed to
  [`httr2::req_retry()`](https://httr2.r-lib.org/reference/req_retry.html).

## Value

An object of class `doclr_client`.

## Examples

``` r
client <- doclr_client("http://localhost:5001")
client
#> <doclr_client>
#> • url: <http://localhost:5001>
#> • api key: none
#> • timeout: 300s
```
