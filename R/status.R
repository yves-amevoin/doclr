#' Create a task object from an async submission response
#'
#' @param result Parsed body of an async convert call.
#' @param client The [doclr_client()] that submitted the task.
#'
#' @return A `doclr_task` object.
#' @noRd
new_doclr_task <- function(result, client) {
  task_id <- result[["task_id"]]
  if (is.null(task_id)) {
    doclr_abort(
      c(
        "The server did not return a task id.",
        "i" = "Does this server support the async endpoints?"
      ),
      class = "task"
    )
  }

  structure(
    list(
      task_id = as.character(task_id),
      status = as.character(result[["task_status"]] %||% "unknown"),
      position = result[["task_position"]],
      client = client
    ),
    class = "doclr_task"
  )
}

#' An asynchronous docling-serve conversion task
#'
#' @description
#' Returned by [doclr_convert_source_async()] and
#' [doclr_convert_file_async()]. Query it with [doclr_task_status()] and
#' collect the finished document with [doclr_task_result()].
#'
#' @name doclr_task
NULL

#' @export
print.doclr_task <- function(x, ...) {
  cli::cli_text("{.cls doclr_task}")
  cli::cli_bullets(c(
    "*" = "task id: {.val {x$task_id}}",
    "*" = "status: {.val {x$status}}"
  ))
  invisible(x)
}

#' Poll the status of an asynchronous task
#'
#' @description
#' Calls `GET /v1/status/poll/{task_id}`. With `wait` greater than zero the
#' server holds the connection open until the status changes or the wait
#' elapses, which is cheaper than tight client-side polling.
#'
#' @param task A [doclr_task] object, or a task id string.
#' @param wait Seconds the server may hold the request open before answering.
#' @param client A [doclr_client()]. Only used when `task` is an id string.
#'
#' @return A one-row tibble with `task_id`, `status` and `position`.
#' @export
#'
#' @examplesIf FALSE
#' task <- doclr_convert_source_async("https://arxiv.org/pdf/2408.09869")
#' doclr_task_status(task)
doclr_task_status <- function(task, wait = 0, client = doclr_client()) {
  parts <- task_parts(task, client)

  result <- doclr_request(
    parts$client,
    paste0("v1/status/poll/", parts$task_id)
  ) |>
    httr2::req_url_query(wait = wait) |>
    doclr_perform_json()

  tibble::tibble(
    task_id = parts$task_id,
    status = as.character(result[["task_status"]] %||% NA_character_),
    position = as.integer(result[["task_position"]] %||% NA_integer_)
  )
}

#' Fetch the result of a finished task
#'
#' @description
#' Calls `GET /v1/result/{task_id}`. The task must have reached the `success`
#' state; ask [doclr_task_status()] first, or let [doclr_convert()] do the
#' waiting for you.
#'
#' @inheritParams doclr_task_status
#'
#' @return A [doclr_document] object, or a list of them.
#' @export
#'
#' @examplesIf FALSE
#' doclr_task_result(task)
doclr_task_result <- function(task, client = doclr_client()) {
  parts <- task_parts(task, client)

  result <- doclr_request(
    parts$client,
    paste0("v1/result/", parts$task_id)
  ) |>
    doclr_perform_json()

  new_document_result(result)
}

#' Convert a document, waiting for the result
#'
#' @description
#' The function most users want. Submits the source asynchronously, shows a
#' `cli` spinner while the server works, and returns the finished document.
#' URLs are sent to the source endpoint and everything else is uploaded, so a
#' mixed vector of URLs and paths is handled in one call.
#'
#' @param source One or more document URLs or local file paths.
#' @param options A [doclr_options()] object.
#' @param client A [doclr_client()].
#' @param poll_interval Seconds between status checks.
#' @param timeout Give up after this many seconds.
#' @param quiet Suppress the progress spinner.
#'
#' @return A [doclr_document] object, or a list of them when several sources
#'   were converted.
#' @export
#'
#' @examplesIf FALSE
#' doc <- doclr_convert("https://arxiv.org/pdf/2408.09869")
#' as_markdown(doc)
doclr_convert <- function(
  source,
  options = doclr_options(),
  client = doclr_client(),
  poll_interval = 2,
  timeout = 600,
  quiet = !interactive()
) {
  check_client(client)
  parts <- split_sources(source)

  if (length(parts$urls) > 0L && length(parts$paths) > 0L) {
    docs <- c(
      as_document_list(
        doclr_convert(
          parts$urls,
          options,
          client,
          poll_interval,
          timeout,
          quiet
        )
      ),
      as_document_list(
        doclr_convert(
          parts$paths,
          options,
          client,
          poll_interval,
          timeout,
          quiet
        )
      )
    )
    return(docs)
  }

  task <- if (length(parts$urls) > 0L) {
    doclr_convert_source_async(parts$urls, options, client)
  } else {
    doclr_convert_file_async(parts$paths, options, client)
  }

  doclr_wait(
    task,
    poll_interval = poll_interval,
    timeout = timeout,
    quiet = quiet
  )
}

#' Wait for a task to finish
#'
#' @inheritParams doclr_convert
#' @param task A [doclr_task] object, or a task id string.
#'
#' @return A [doclr_document] object, or a list of them.
#' @export
#'
#' @examplesIf FALSE
#' task <- doclr_convert_file_async("report.pdf")
#' doclr_wait(task)
doclr_wait <- function(
  task,
  client = doclr_client(),
  poll_interval = 2,
  timeout = 600,
  quiet = !interactive()
) {
  parts <- task_parts(task, client)
  deadline <- Sys.time() + timeout

  if (!quiet) {
    cli::cli_progress_bar(
      format = "{cli::pb_spin} Converting {.val {parts$task_id}} [{status}]",
      clear = TRUE,
      .envir = rlang::current_env()
    )
  }

  status <- "pending"
  repeat {
    state <- doclr_task_status(
      parts$task_id,
      wait = poll_interval,
      client = parts$client
    )
    status <- state$status

    if (!quiet) {
      cli::cli_progress_update(.envir = rlang::current_env())
    }

    if (identical(status, "success")) {
      break
    }

    if (status %in% c("failure", "error", "revoked")) {
      doclr_abort(
        c(
          "Conversion task {.val {parts$task_id}} did not succeed.",
          "x" = "Server reported status {.val {status}}."
        ),
        class = "task",
        task_id = parts$task_id,
        status = status
      )
    }

    if (Sys.time() > deadline) {
      doclr_abort(
        c(
          "Timed out after {timeout}s waiting for {.val {parts$task_id}}.",
          "i" = "The task is still on the server; retry with {.fun doclr_wait}.",
          "i" = "Last known status: {.val {status}}."
        ),
        class = "timeout",
        task_id = parts$task_id,
        status = status
      )
    }
  }

  doclr_task_result(parts$task_id, client = parts$client)
}

#' Normalise a task argument into an id and a client
#'
#' @param task A `doclr_task` object or a task id string.
#' @param client Fallback client used when `task` is an id string.
#' @param call The calling environment, for error reporting.
#'
#' @return A list with `task_id` and `client`.
#' @noRd
task_parts <- function(task, client, call = rlang::caller_env()) {
  if (inherits(task, "doclr_task")) {
    return(list(task_id = task$task_id, client = task$client))
  }

  check_string(task, arg = "task", call = call)
  check_client(client, call = call)
  list(task_id = task, client = client)
}
