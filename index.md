# doclr

**doclr** is a pure-R client for the
[docling-serve](https://docling-project.github.io/docling/usage/api_server/rest_api/)
REST API. It turns PDFs, Office files, images and HTML into Markdown,
plain text, HTML, structured JSON or DocTags, by talking to a
docling-serve instance over HTTP.

There is no Python in the loop. `doclr` speaks HTTP with `httr2`, so the
R side has no `reticulate` dependency and no model stack to install.

## Where doclr sits

| Package | Language | How it works |
|----|----|----|
| `doclr` (this one) | R | REST client for docling-serve |
| `docling-client` | Python | REST client for docling-serve |
| `doclingr` (CRAN) | R | runs Python’s `docling` in-process via reticulate |

If you already know the Python ecosystem: `doclr` is the R sibling of
`docling-client`, not of `doclingr`. It is a slim, remote-first wrapper
— the models run on the server, not in your session.

## Installation

``` r

pak::pak("yves-amevoin/doclr")
```

## Getting a server

Point `doclr` at a docling-serve that already exists — a colleague’s, a
shared instance, anything reachable over HTTP:

``` r

library(doclr)

client <- doclr_client("https://docling.example.org", api_key = "…")
doclr_health(client)
```

Or provision one locally.
[`doclr_setup()`](https://yves-amevoin.github.io/doclr/reference/doclr_setup.md)
is explicit and interactive by design: it never runs on load or attach,
and it asks before installing anything.

``` r

doclr_setup()
```

It checks, in order, whether a server already answers, whether Podman or
Docker is on your `PATH`, whether a package manager could install
Podman, whether Python is available for
`pip install "docling-serve[ui]"`, and finally — on a locked-down
machine with none of the above — asks for the URL of a remote server
rather than guessing.

Once set up, the container is managed with:

``` r

doclr_server_start()
doclr_server_status()
doclr_server_stop()
```

The first image pull is several hundred megabytes, because today’s
`docling-serve` image bundles model weights.

## Converting a document

[`doclr_convert()`](https://yves-amevoin.github.io/doclr/reference/doclr_convert.md)
is the one function most work goes through. It submits the job
asynchronously, polls with a progress spinner, and returns the finished
document:

``` r

doc <- doclr_convert("https://arxiv.org/pdf/2408.09869")

doc
#> <doclr_document>
#> * file: "2408.09869v5.pdf"
#> * status: "success"
#> * formats: "md"

cat(as_markdown(doc))
```

Local files go through the same call — anything that is not an `http(s)`
URL is uploaded:

``` r

doc <- doclr_convert("reports/quarterly.pdf")
```

Ask for more than one representation, then pull each one out:

``` r

doc <- doclr_convert(
  "reports/quarterly.pdf",
  doclr_options(to_formats = c("md", "json"), do_ocr = TRUE)
)

as_markdown(doc)
as_json(doc)     # structured tree: tables, figures, reading order
```

### Sync, async, and the pieces underneath

| Function | Endpoint |
|----|----|
| [`doclr_convert_source()`](https://yves-amevoin.github.io/doclr/reference/doclr_convert_source.md) | `POST /v1/convert/source` |
| [`doclr_convert_file()`](https://yves-amevoin.github.io/doclr/reference/doclr_convert_file.md) | `POST /v1/convert/file` |
| [`doclr_convert_source_async()`](https://yves-amevoin.github.io/doclr/reference/doclr_convert_source_async.md) | `POST /v1/convert/source/async` |
| [`doclr_convert_file_async()`](https://yves-amevoin.github.io/doclr/reference/doclr_convert_file_async.md) | `POST /v1/convert/file/async` |
| [`doclr_task_status()`](https://yves-amevoin.github.io/doclr/reference/doclr_task_status.md) | `GET /v1/status/poll/{task_id}` |
| [`doclr_task_result()`](https://yves-amevoin.github.io/doclr/reference/doclr_task_result.md) | `GET /v1/result/{task_id}` |

Drive the async flow yourself when you want to do something else while
the server works:

``` r

task <- doclr_convert_file_async("big-scan.pdf")
doclr_task_status(task)
#> # A tibble: 1 × 3
#>   task_id  status  position
#>   <chr>    <chr>      <int>
#> 1 8f3c…    started        0

doc <- doclr_wait(task)
```

## Configuration

| Variable                | Purpose                                        |
|-------------------------|------------------------------------------------|
| `DOCLING_SERVE_URL`     | default base URL, else `http://localhost:5001` |
| `DOCLING_SERVE_API_KEY` | sent as a redacted `X-Api-Key` header          |

## Errors

Every failure is an `rlang` condition with a `doclr_error_*` class, so
you can catch exactly the case you care about:

``` r

tryCatch(
  doclr_convert("broken.pdf"),
  doclr_error_connection = function(e) message("No server running."),
  doclr_error_timeout = function(e) message("Still going; try doclr_wait().")
)
```

Classes in use: `doclr_error_input`, `doclr_error_client`,
`doclr_error_http`, `doclr_error_connection`, `doclr_error_task`,
`doclr_error_timeout`, `doclr_error_format`, `doclr_error_engine`,
`doclr_error_setup`.

## License

MIT
