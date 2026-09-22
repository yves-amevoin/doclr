# Conversion options accepted by docling-serve

Builds the `options` object sent with a conversion request. Only the
arguments you set are transmitted, so the server's own defaults apply to
everything else.

## Usage

``` r
doclr_options(
  to_formats = "md",
  from_formats = NULL,
  do_ocr = NULL,
  ocr_lang = NULL,
  do_table_structure = NULL,
  table_mode = NULL,
  image_export_mode = NULL,
  include_images = NULL,
  abort_on_error = NULL,
  ...
)
```

## Arguments

- to_formats:

  Output formats to produce. Any of `"md"`, `"json"`, `"html"`,
  `"text"`, `"doctags"`.

- from_formats:

  Input formats the server should accept, e.g. `"pdf"`, `"docx"`,
  `"html"`. `NULL` lets the server decide.

- do_ocr:

  Run OCR on scanned content.

- ocr_lang:

  Character vector of OCR language codes, e.g. `c("eng", "fra")`.

- do_table_structure:

  Recover table structure.

- table_mode:

  Table model to use, `"fast"` or `"accurate"`.

- image_export_mode:

  How images are returned: `"placeholder"`, `"embedded"` or
  `"referenced"`.

- include_images:

  Include images in the converted output.

- abort_on_error:

  Ask the server to fail the whole request when one source fails.

- ...:

  Further options passed through verbatim to the API, for fields this
  package does not name explicitly.

## Value

A named list of options, class `doclr_options`.

## Examples

``` r
doclr_options(to_formats = c("md", "json"), do_ocr = TRUE)
#> <doclr_options>
#> • to_formats: "md" and "json"
#> • do_ocr: TRUE
```
