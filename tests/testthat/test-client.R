test_that("doclr_client builds a client from explicit arguments", {
  client <- doclr_client("http://example.com:5001/", api_key = "secret")

  expect_s3_class(client, "doclr_client")
  expect_true(is_doclr_client(client))
  expect_equal(client$url, "http://example.com:5001")
  expect_true(client$has_api_key)
})

test_that("doclr_client falls back to environment variables", {
  withr::local_envvar(
    DOCLING_SERVE_URL = "http://env-host:1234",
    DOCLING_SERVE_API_KEY = "env-key"
  )

  client <- doclr_client()

  expect_equal(client$url, "http://env-host:1234")
  expect_true(client$has_api_key)
})

test_that("an empty api key means no authentication", {
  withr::local_envvar(DOCLING_SERVE_API_KEY = "")

  expect_false(doclr_client("http://localhost:5001")$has_api_key)
})

test_that("doclr_client rejects malformed arguments", {
  expect_error(doclr_client(url = 1), class = "doclr_error_input")
  expect_error(doclr_client(url = ""), class = "doclr_error_input")
  expect_error(
    doclr_client("http://localhost:5001", timeout = -1),
    class = "doclr_error_input"
  )
})

test_that("the api key is sent as a redacted header", {
  client <- doclr_client("http://localhost:5001", api_key = "secret")
  printed <- paste(capture.output(print(client$request)), collapse = "\n")

  expect_match(printed, "X-Api-Key")
  expect_match(printed, "REDACTED")
  expect_no_match(printed, "secret")
})

test_that("no api key header is sent when none is set", {
  client <- doclr_client("http://localhost:5001", api_key = NULL)
  printed <- paste(capture.output(print(client$request)), collapse = "\n")

  expect_no_match(printed, "X-Api-Key")
})

test_that("doclr_health reports FALSE when the server refuses", {
  client <- doclr_client("http://localhost:5001")
  httr2::local_mocked_responses(function(req) {
    json_response(list(detail = "nope"), status = 503L)
  })

  expect_false(doclr_health(client))
})

test_that("doclr_health reports TRUE when the server answers", {
  client <- doclr_client("http://localhost:5001")
  httr2::local_mocked_responses(function(req) {
    json_response(list(status = "ok"))
  })

  expect_true(doclr_health(client))
})

test_that("non-clients are rejected", {
  expect_error(doclr_health("http://localhost:5001"), class = "doclr_error_client")
})
