#' A converted docling document
#'
#' @description
#' The object returned by [doclr_convert()] and friends. It holds whichever
#' representations the server produced — controlled by the `to_formats`
#' argument of [doclr_options()] — plus the conversion status and any errors
#' the server reported. Pull content out with [as_markdown()], [as_text()],
#' [as_html()], [as_json()] or [as_doctags()].
#'
#' @name doclr_document
NULL

#' Build a document object from a conversion response
#'
#' @param result Parsed body of a convert or result call.
#'
#' @return A `doclr_document`, or a list of them when the response carried
#'   several documents.
#' @noRd
new_document_result <- function(result) {
  documents <- result[["documents"]]

  if (!is.null(documents) && length(documents) > 0L) {
    docs <- lapply(documents, new_doclr_document, envelope = result)
    if (length(docs) == 1L) {
      return(docs[[1L]])
    }
    return(docs)
  }

  new_doclr_document(result[["document"]] %||% list(), envelope = result)
}

#' Build a single document object
#'
#' @param document The `document` element of a conversion response.
#' @param envelope The full response, carrying status, timing and errors.
#'
#' @return A `doclr_document` object.
#' @noRd
new_doclr_document <- function(document, envelope = list()) {
  document <- document %||% list()

  structure(
    list(
      filename = as.character(document[["filename"]] %||% NA_character_),
      status = as.character(envelope[["status"]] %||% NA_character_),
      processing_time = as.numeric(
        envelope[["processing_time"]] %||% NA_real_
      ),
      errors = envelope[["errors"]] %||% list(),
      content = compact(list(
        md = document[["md_content"]],
        text = document[["text_content"]],
        html = document[["html_content"]],
        json = document[["json_content"]],
        doctags = document[["doctags_content"]]
      ))
    ),
    class = "doclr_document"
  )
}

#' Test whether an object is a converted document
#'
#' @param x An object.
#'
#' @return `TRUE` if `x` is a `doclr_document`, otherwise `FALSE`.
#' @export
#'
#' @examples
#' is_doclr_document(1)
is_doclr_document <- function(x) {
  inherits(x, "doclr_document")
}

#' Wrap a single document in a list
#'
#' @param x A `doclr_document` or a list of them.
#'
#' @return A list of documents.
#' @noRd
as_document_list <- function(x) {
  if (is_doclr_document(x)) list(x) else x
}

#' @export
print.doclr_document <- function(x, ...) {
  cli::cli_text("{.cls doclr_document}")
  formats <- names(x$content)
  cli::cli_bullets(c(
    "*" = "file: {.val {x$filename}}",
    "*" = "status: {.val {x$status}}",
    "*" = "formats: {.val {formats}}"
  ))
  if (length(x$errors) > 0L) {
    cli::cli_bullets(c("!" = "{length(x$errors)} error{?s} reported."))
  }
  invisible(x)
}

#' @export
format.doclr_document <- function(x, ...) {
  as_markdown(x)
}

#' Pull one representation out of a document
#'
#' @param x A [doclr_document].
#' @param format Name of the stored representation.
#' @param call The calling environment, for error reporting.
#'
#' @return A single string.
#' @noRd
document_content <- function(x, format, call = rlang::caller_env()) {
  if (!is_doclr_document(x)) {
    doclr_abort(
      c(
        "{.arg x} must be a {.cls doclr_document}.",
        "x" = "You supplied {.obj_type_friendly {x}}."
      ),
      class = "input",
      call = call
    )
  }

  content <- x$content[[format]]
  if (is.null(content)) {
    available <- names(x$content)
    doclr_abort(
      c(
        "This document has no {.val {format}} content.",
        "i" = if (length(available) > 0L) {
          "Available: {.val {available}}."
        } else {
          "The document carries no content at all."
        },
        "i" = "Request it with {.code doclr_options(to_formats = \"{format}\")}."
      ),
      class = "format",
      call = call
    )
  }

  as.character(content)
}

#' Reject an object that is not a converted document
#'
#' Shared body of the `as_*` default methods, so that passing the wrong kind
#' of object gives a doclr condition rather than an R dispatch error.
#'
#' @param x The offending object.
#' @param call The calling environment, for error reporting.
#'
#' @return Never returns; throws a condition.
#' @noRd
abort_not_document <- function(x, call = rlang::caller_env()) {
  doclr_abort(
    c(
      "{.arg x} must be a {.cls doclr_document}.",
      "x" = "You supplied {.obj_type_friendly {x}}.",
      "i" = "Documents come from {.fun doclr_convert} and friends."
    ),
    class = "input",
    call = call
  )
}

#' Render a converted document as Markdown
#'
#' @param x A [doclr_document].
#' @param ... Unused, for extensibility.
#'
#' @return A single string of Markdown.
#' @export
#'
#' @examplesIf FALSE
#' as_markdown(doclr_convert("https://arxiv.org/pdf/2408.09869"))
as_markdown <- function(x, ...) {
  UseMethod("as_markdown")
}

#' @export
as_markdown.doclr_document <- function(x, ...) {
  document_content(x, "md")
}

#' @export
as_markdown.default <- function(x, ...) {
  abort_not_document(x)
}

#' Render a converted document as plain text
#'
#' @inheritParams as_markdown
#'
#' @return A single string of plain text.
#' @export
#'
#' @examplesIf FALSE
#' as_text(doclr_convert("report.pdf", doclr_options(to_formats = "text")))
as_text <- function(x, ...) {
  UseMethod("as_text")
}

#' @export
as_text.doclr_document <- function(x, ...) {
  document_content(x, "text")
}

#' @export
as_text.default <- function(x, ...) {
  abort_not_document(x)
}

#' Render a converted document as HTML
#'
#' @inheritParams as_markdown
#'
#' @return A single string of HTML.
#' @export
#'
#' @examplesIf FALSE
#' as_html(doclr_convert("report.pdf", doclr_options(to_formats = "html")))
as_html <- function(x, ...) {
  UseMethod("as_html")
}

#' @export
as_html.doclr_document <- function(x, ...) {
  document_content(x, "html")
}

#' @export
as_html.default <- function(x, ...) {
  abort_not_document(x)
}

#' Extract the structured JSON representation of a document
#'
#' @description
#' Returns the docling JSON tree, which is where tables, figures and reading
#' order live.
#'
#' @inheritParams as_markdown
#' @param simplify Passed to [jsonlite::fromJSON()] when the server sent the
#'   JSON as a string. Set `FALSE` to keep a faithful nested list.
#'
#' @return A named list.
#' @export
#'
#' @examplesIf FALSE
#' json <- as_json(doclr_convert("report.pdf", doclr_options(to_formats = "json")))
#' names(json)
as_json <- function(x, simplify = FALSE, ...) {
  UseMethod("as_json")
}

#' @export
as_json.default <- function(x, simplify = FALSE, ...) {
  abort_not_document(x)
}

#' @export
as_json.doclr_document <- function(x, simplify = FALSE, ...) {
  content <- x$content[["json"]]
  if (is.null(content)) {
    document_content(x, "json")
  }

  if (is.character(content)) {
    return(jsonlite::fromJSON(content, simplifyVector = simplify))
  }

  content
}

#' Render a converted document as DocTags
#'
#' @inheritParams as_markdown
#'
#' @return A single string of DocTags markup.
#' @export
#'
#' @examplesIf FALSE
#' as_doctags(doclr_convert("report.pdf", doclr_options(to_formats = "doctags")))
as_doctags <- function(x, ...) {
  UseMethod("as_doctags")
}

#' @export
as_doctags.doclr_document <- function(x, ...) {
  document_content(x, "doctags")
}

#' @export
as_doctags.default <- function(x, ...) {
  abort_not_document(x)
}
