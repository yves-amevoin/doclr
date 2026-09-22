test_that("an async submission produces a task", {
  httr2::local_mocked_responses(function(req) {
    json_response(list(task_id = "abc123", task_status = "pending", task_position = 0))
  })

  task <- doclr_convert_source_async(
    "https://a.test/x.pdf",
    client = doclr_client("http://localhost:5001")
  )

  expect_s3_class(task, "doclr_task")
  expect_equal(task$task_id, "abc123")
  expect_equal(task$status, "pending")
})

test_that("a response without a task id is an error", {
  httr2::local_mocked_responses(function(req) {
    json_response(list(detail = "not supported"))
  })

  expect_error(
    doclr_convert_source_async(
      "https://a.test/x.pdf",
      client = doclr_client("http://localhost:5001")
    ),
    class = "doclr_error_task"
  )
})

test_that("doclr_task_status returns a one-row tibble", {
  httr2::local_mocked_responses(function(req) {
    json_response(list(task_status = "started", task_position = 2))
  })

  state <- doclr_task_status("abc123", client = doclr_client("http://localhost:5001"))

  expect_s3_class(state, "tbl_df")
  expect_equal(nrow(state), 1L)
  expect_equal(state$task_id, "abc123")
  expect_equal(state$status, "started")
  expect_equal(state$position, 2L)
})

test_that("doclr_wait polls until the task succeeds", {
  httr2::local_mocked_responses(mock_sequence(list(
    json_response(list(task_status = "pending", task_position = 1)),
    json_response(list(task_status = "started", task_position = 0)),
    json_response(list(task_status = "success", task_position = 0)),
    json_response(fake_convert_response())
  )))

  doc <- doclr_wait(
    "abc123",
    client = doclr_client("http://localhost:5001"),
    poll_interval = 0,
    quiet = TRUE
  )

  expect_s3_class(doc, "doclr_document")
  expect_equal(as_markdown(doc), "# Sample\n\nHello world.")
})

test_that("a failed task raises a task error", {
  httr2::local_mocked_responses(function(req) {
    json_response(list(task_status = "failure", task_position = 0))
  })

  expect_error(
    doclr_wait(
      "abc123",
      client = doclr_client("http://localhost:5001"),
      poll_interval = 0,
      quiet = TRUE
    ),
    class = "doclr_error_task"
  )
})

test_that("waiting past the timeout raises a timeout error", {
  httr2::local_mocked_responses(function(req) {
    json_response(list(task_status = "pending", task_position = 1))
  })

  expect_error(
    doclr_wait(
      "abc123",
      client = doclr_client("http://localhost:5001"),
      poll_interval = 0,
      timeout = 0,
      quiet = TRUE
    ),
    class = "doclr_error_timeout"
  )
})

test_that("doclr_convert drives the whole async round trip", {
  httr2::local_mocked_responses(mock_sequence(list(
    json_response(list(task_id = "abc123", task_status = "pending")),
    json_response(list(task_status = "success", task_position = 0)),
    json_response(fake_convert_response())
  )))

  doc <- doclr_convert(
    "https://a.test/x.pdf",
    client = doclr_client("http://localhost:5001"),
    poll_interval = 0,
    quiet = TRUE
  )

  expect_s3_class(doc, "doclr_document")
})
