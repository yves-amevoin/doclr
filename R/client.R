#' Create a connection to a docling-serve server
#'
#' @description
#' Builds a lightweight handle holding the base URL, credentials and request
#' policy used by every other function in the package. Nothing is sent to the
#' server until you call [doclr_health()] or one of the convert functions.
#'
#' @param url Base URL of the docling-serve server. Defaults to the
#'   `DOCLING_SERVE_URL` environment variable, falling back to
#'   `"http://localhost:5001"`.
#' @param api_key API key sent as an `X-Api-Key` header. Defaults to the
#'   `DOCLING_SERVE_API_KEY` environment variable; `NULL` or `""` means no
#'   authentication, which is the usual case for a local server.
#' @param timeout Request timeout in seconds.
#' @param max_tries Number of attempts for transient failures, passed to
#'   [httr2::req_retry()].
#'
#' @return An object of class `doclr_client`.
#' @export
#'
#' @examples
#' client <- doclr_client("http://localhost:5001")
#' client
doclr_client <- function(
  url = Sys.getenv("DOCLING_SERVE_URL", DOCLR_DEFAULT_URL),
  api_key = Sys.getenv("DOCLING_SERVE_API_KEY"),
  timeout = 300,
  max_tries = 3
) {
  check_string(url)

  if (!is.numeric(timeout) || length(timeout) != 1L || timeout <= 0) {
    doclr_abort(
      "{.arg timeout} must be a single positive number.",
      class = "input"
    )
  }

  url <- sub("/+$", "", url)

  req <- httr2::request(url) |>
    httr2::req_user_agent(doclr_user_agent()) |>
    httr2::req_timeout(timeout) |>
    httr2::req_retry(max_tries = max_tries)

  if (!is.null(api_key) && nzchar(api_key)) {
    req <- httr2::req_headers(req, "X-Api-Key" = api_key, .redact = "X-Api-Key")
  }

  structure(
    list(
      url = url,
      has_api_key = !is.null(api_key) && nzchar(api_key),
      timeout = timeout,
      request = req
    ),
    class = "doclr_client"
  )
}

#' Test whether an object is a doclr client
#'
#' @param x An object.
#'
#' @return `TRUE` if `x` is a `doclr_client`, otherwise `FALSE`.
#' @export
#'
#' @examples
#' is_doclr_client(doclr_client())
#' is_doclr_client(1)
is_doclr_client <- function(x) {
  inherits(x, "doclr_client")
}

#' @export
print.doclr_client <- function(x, ...) {
  cli::cli_text("{.cls doclr_client}")
  cli::cli_bullets(c(
    "*" = "url: {.url {x$url}}",
    "*" = "api key: {if (x$has_api_key) 'set' else 'none'}",
    "*" = "timeout: {x$timeout}s"
  ))
  invisible(x)
}

#' Check that a docling-serve server is reachable
#'
#' @param client A [doclr_client()].
#'
#' @return `TRUE` if the server answers its health endpoint, otherwise `FALSE`.
#' @export
#'
#' @examplesIf FALSE
#' doclr_health(doclr_client())
doclr_health <- function(client = doclr_client()) {
  check_client(client)

  resp <- tryCatch(
    doclr_request(client, "health") |>
      httr2::req_retry(max_tries = 1) |>
      httr2::req_timeout(5) |>
      httr2::req_error(is_error = function(resp) FALSE) |>
      httr2::req_perform(),
    error = function(e) NULL
  )

  !is.null(resp) && httr2::resp_status(resp) < 400L
}

#' User agent string sent with every request
#'
#' @return A single string.
#' @noRd
doclr_user_agent <- function() {
  version <- tryCatch(
    as.character(utils::packageVersion("doclr")),
    error = function(e) "dev"
  )
  paste0("doclr/", version, " (httr2)")
}
