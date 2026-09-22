#' Default docling-serve base URL
#'
#' The URL used when neither an explicit `url` nor the
#' `DOCLING_SERVE_URL` environment variable is supplied.
#'
#' @noRd
DOCLR_DEFAULT_URL <- "http://localhost:5001"

#' Container image used for local provisioning
#'
#' Kept in one place on purpose: today's image bundles model weights and is
#' several hundred megabytes on first pull. A slimmer upstream image should be
#' a one-line change here.
#'
#' @noRd
DOCLR_IMAGE <- "quay.io/docling-project/docling-serve"

#' Raise a doclr condition
#'
#' @param message Character vector passed to [rlang::abort()]; supports the
#'   `cli` bullet syntax.
#' @param class Suffix appended to `doclr_error_` to build the condition class.
#' @param ... Extra data stored on the condition object.
#' @param call The calling environment, for error reporting.
#'
#' @return Never returns; throws a condition.
#' @noRd
doclr_abort <- function(
  message,
  class = "generic",
  ...,
  call = rlang::caller_env()
) {
  rlang::abort(
    message,
    class = c(paste0("doclr_error_", class), "doclr_error"),
    ...,
    call = call
  )
}

#' Check that an object is a doclr client
#'
#' @param client Object to check.
#' @param call The calling environment, for error reporting.
#'
#' @return `client`, invisibly.
#' @noRd
check_client <- function(client, call = rlang::caller_env()) {
  if (!is_doclr_client(client)) {
    doclr_abort(
      c(
        "{.arg client} must be a {.cls doclr_client}.",
        "x" = "You supplied {.obj_type_friendly {client}}.",
        "i" = "Create one with {.fun doclr_client}."
      ),
      class = "client",
      call = call
    )
  }
  invisible(client)
}

#' Check that a value is a single non-empty string
#'
#' @param x Value to check.
#' @param arg Name of the argument being checked.
#' @param call The calling environment, for error reporting.
#'
#' @return `x`, invisibly.
#' @noRd
check_string <- function(
  x,
  arg = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    doclr_abort(
      c(
        "{.arg {arg}} must be a single non-empty string.",
        "x" = "You supplied {.obj_type_friendly {x}}."
      ),
      class = "input",
      call = call
    )
  }
  invisible(x)
}

#' Build a request against a docling-serve endpoint
#'
#' Applies the client's base URL, authentication header, user agent, timeout
#' and retry policy, then appends `path`.
#'
#' @param client A [doclr_client()].
#' @param path Endpoint path, e.g. `"v1/convert/source"`.
#' @param method Optional HTTP method to force (`"POST"`, `"GET"`, ...).
#'
#' @return An [httr2::request()].
#' @noRd
doclr_request <- function(client, path, method = NULL) {
  check_client(client)
  check_string(path)

  req <- client$request |>
    httr2::req_url_path_append(path) |>
    httr2::req_error(body = doclr_error_body)

  if (!is.null(method)) {
    req <- httr2::req_method(req, method)
  }

  req
}

#' Extract a useful message from a docling-serve error response
#'
#' @param resp An [httr2::response()].
#'
#' @return A character vector of error bullets, or `NULL`.
#' @noRd
doclr_error_body <- function(resp) {
  body <- tryCatch(
    httr2::resp_body_json(resp, check_type = FALSE),
    error = function(e) NULL
  )
  if (is.null(body)) {
    return(NULL)
  }

  detail <- body[["detail"]] %||% body[["message"]] %||% body[["error"]]
  if (is.null(detail)) {
    return(NULL)
  }

  # FastAPI validation errors arrive as a list of {loc, msg, type} objects.
  if (is.list(detail)) {
    detail <- vapply(
      detail,
      function(item) {
        if (is.list(item)) {
          as.character(
            item[["msg"]] %||% jsonlite::toJSON(item, auto_unbox = TRUE)
          )
        } else {
          as.character(item)
        }
      },
      character(1)
    )
  }

  as.character(detail)
}

#' Perform a request and return the parsed JSON body
#'
#' @param req An [httr2::request()].
#' @param call The calling environment, for error reporting.
#'
#' @return The response body parsed as a named list.
#' @noRd
doclr_perform_json <- function(req, call = rlang::caller_env()) {
  resp <- tryCatch(
    httr2::req_perform(req),
    httr2_http = function(cnd) {
      doclr_abort(
        c(
          "The docling-serve request failed.",
          "x" = conditionMessage(cnd)
        ),
        class = "http",
        status = httr2::resp_status(cnd$resp),
        resp = cnd$resp,
        call = call
      )
    },
    httr2_failure = function(cnd) {
      doclr_abort(
        c(
          "Could not reach the docling-serve server.",
          "x" = conditionMessage(cnd),
          "i" = "Is a server running? See {.fun doclr_server_status}."
        ),
        class = "connection",
        call = call
      )
    }
  )

  httr2::resp_body_json(resp, simplifyVector = FALSE)
}

#' Null-coalescing operator
#'
#' @param x,y Values; `y` is returned when `x` is `NULL`.
#'
#' @return `x` if it is not `NULL`, otherwise `y`.
#' @noRd
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Drop NULL elements from a list
#'
#' @param x A list.
#'
#' @return `x` without its `NULL` elements.
#' @noRd
compact <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}
