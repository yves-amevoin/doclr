#' Conversion options accepted by docling-serve
#'
#' @description
#' Builds the `options` object sent with a conversion request. Only the
#' arguments you set are transmitted, so the server's own defaults apply to
#' everything else.
#'
#' @param to_formats Output formats to produce. Any of `"md"`, `"json"`,
#'   `"html"`, `"text"`, `"doctags"`.
#' @param from_formats Input formats the server should accept, e.g. `"pdf"`,
#'   `"docx"`, `"html"`. `NULL` lets the server decide.
#' @param do_ocr Run OCR on scanned content.
#' @param ocr_lang Character vector of OCR language codes, e.g. `c("eng", "fra")`.
#' @param do_table_structure Recover table structure.
#' @param table_mode Table model to use, `"fast"` or `"accurate"`.
#' @param image_export_mode How images are returned: `"placeholder"`,
#'   `"embedded"` or `"referenced"`.
#' @param include_images Include images in the converted output.
#' @param abort_on_error Ask the server to fail the whole request when one
#'   source fails.
#' @param ... Further options passed through verbatim to the API, for fields
#'   this package does not name explicitly.
#'
#' @return A named list of options, class `doclr_options`.
#' @export
#'
#' @examples
#' doclr_options(to_formats = c("md", "json"), do_ocr = TRUE)
doclr_options <- function(
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
) {
  if (!is.character(to_formats) || length(to_formats) == 0L) {
    doclr_abort(
      "{.arg to_formats} must be a character vector with at least one format.",
      class = "input"
    )
  }

  opts <- compact(list(
    to_formats = as.list(to_formats),
    from_formats = if (!is.null(from_formats)) as.list(from_formats),
    do_ocr = do_ocr,
    ocr_lang = if (!is.null(ocr_lang)) as.list(ocr_lang),
    do_table_structure = do_table_structure,
    table_mode = table_mode,
    image_export_mode = image_export_mode,
    include_images = include_images,
    abort_on_error = abort_on_error,
    ...
  ))

  structure(opts, class = c("doclr_options", "list"))
}

#' @export
print.doclr_options <- function(x, ...) {
  cli::cli_text("{.cls doclr_options}")
  for (nm in names(x)) {
    value <- unlist(x[[nm]])
    cli::cli_bullets(c("*" = "{nm}: {.val {value}}"))
  }
  invisible(x)
}

#' Describe a source for conversion
#'
#' @param source A URL, a local file path, or a list of either. Anything that
#'   looks like `http://` or `https://` is sent as a URL source; everything
#'   else is treated as a path to upload.
#'
#' @return A list with `urls` and `paths` character vectors.
#' @noRd
split_sources <- function(source) {
  source <- unlist(source, use.names = FALSE)
  if (!is.character(source) || length(source) == 0L) {
    doclr_abort(
      "{.arg source} must be a character vector of URLs or file paths.",
      class = "input"
    )
  }

  is_url <- grepl("^https?://", source)
  list(urls = source[is_url], paths = source[!is_url])
}

#' Convert documents given by URL
#'
#' @description
#' Calls `POST /v1/convert/source`, which blocks until the conversion
#' finishes. Use [doclr_convert()] for anything long enough that you would
#' rather poll.
#'
#' @param urls Character vector of document URLs.
#' @param options A [doclr_options()] object.
#' @param client A [doclr_client()].
#'
#' @return A [doclr_document] object, or a list of them when several sources
#'   were converted.
#' @export
#'
#' @examplesIf FALSE
#' doclr_convert_source("https://arxiv.org/pdf/2408.09869")
doclr_convert_source <- function(
  urls,
  options = doclr_options(),
  client = doclr_client()
) {
  check_client(client)
  body <- convert_source_body(urls, options)

  result <- doclr_request(client, "v1/convert/source") |>
    httr2::req_body_json(body) |>
    doclr_perform_json()

  new_document_result(result)
}

#' Convert documents by uploading local files
#'
#' @description
#' Calls `POST /v1/convert/file`, which blocks until the conversion finishes.
#'
#' @param paths Character vector of local file paths.
#' @param options A [doclr_options()] object.
#' @param client A [doclr_client()].
#'
#' @return A [doclr_document] object, or a list of them when several files
#'   were converted.
#' @export
#'
#' @examplesIf FALSE
#' doclr_convert_file("report.pdf")
doclr_convert_file <- function(
  paths,
  options = doclr_options(),
  client = doclr_client()
) {
  check_client(client)

  result <- doclr_request(client, "v1/convert/file") |>
    req_body_files(paths, options) |>
    doclr_perform_json()

  new_document_result(result)
}

#' Submit a URL conversion as an asynchronous task
#'
#' @inheritParams doclr_convert_source
#'
#' @return A [doclr_task] object.
#' @export
#'
#' @examplesIf FALSE
#' task <- doclr_convert_source_async("https://arxiv.org/pdf/2408.09869")
#' doclr_task_status(task)
doclr_convert_source_async <- function(
  urls,
  options = doclr_options(),
  client = doclr_client()
) {
  check_client(client)
  body <- convert_source_body(urls, options)

  result <- doclr_request(client, "v1/convert/source/async") |>
    httr2::req_body_json(body) |>
    doclr_perform_json()

  new_doclr_task(result, client)
}

#' Submit a file conversion as an asynchronous task
#'
#' @inheritParams doclr_convert_file
#'
#' @return A [doclr_task] object.
#' @export
#'
#' @examplesIf FALSE
#' task <- doclr_convert_file_async("report.pdf")
#' doclr_task_status(task)
doclr_convert_file_async <- function(
  paths,
  options = doclr_options(),
  client = doclr_client()
) {
  check_client(client)

  result <- doclr_request(client, "v1/convert/file/async") |>
    req_body_files(paths, options) |>
    doclr_perform_json()

  new_doclr_task(result, client)
}

#' Build the JSON body for a URL conversion
#'
#' @param urls Character vector of document URLs.
#' @param options A [doclr_options()] object.
#'
#' @return A named list ready for [httr2::req_body_json()].
#' @noRd
convert_source_body <- function(urls, options) {
  urls <- unlist(urls, use.names = FALSE)
  if (!is.character(urls) || length(urls) == 0L) {
    doclr_abort(
      "{.arg urls} must be a character vector of URLs.",
      class = "input"
    )
  }

  bad <- urls[!grepl("^https?://", urls)]
  if (length(bad) > 0L) {
    doclr_abort(
      c(
        "{.arg urls} must contain http(s) URLs.",
        "x" = "Not a URL: {.val {bad}}.",
        "i" = "Use {.fun doclr_convert_file} for local files."
      ),
      class = "input"
    )
  }

  list(
    options = unclass(options),
    sources = lapply(urls, function(u) list(kind = "http", url = u))
  )
}

#' Attach files and options to a multipart request
#'
#' Options are flattened into repeated form fields, which is how
#' docling-serve's file endpoints expect them.
#'
#' @param req An [httr2::request()].
#' @param paths Character vector of local file paths.
#' @param options A [doclr_options()] object.
#'
#' @return The request with a multipart body.
#' @noRd
req_body_files <- function(req, paths, options) {
  paths <- unlist(paths, use.names = FALSE)
  if (!is.character(paths) || length(paths) == 0L) {
    doclr_abort(
      "{.arg paths} must be a character vector of file paths.",
      class = "input"
    )
  }

  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0L) {
    doclr_abort(
      c("Some files do not exist.", "x" = "{.file {missing}}"),
      class = "input"
    )
  }

  parts <- lapply(paths, curl::form_file)
  names(parts) <- rep("files", length(parts))

  fields <- flatten_options(options)

  rlang::exec(httr2::req_body_multipart, req, !!!c(parts, fields))
}

#' Flatten conversion options into multipart form fields
#'
#' @param options A [doclr_options()] object.
#'
#' @return A named list of character scalars, with repeated names for
#'   vector-valued options.
#' @noRd
flatten_options <- function(options) {
  out <- list()
  for (nm in names(options)) {
    values <- unlist(options[[nm]], use.names = FALSE)
    if (is.logical(values)) {
      values <- ifelse(values, "true", "false")
    }
    for (value in as.character(values)) {
      out[[length(out) + 1L]] <- value
      names(out)[length(out)] <- nm
    }
  }
  out
}
