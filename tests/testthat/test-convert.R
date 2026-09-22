test_that("doclr_options keeps only the fields that were set", {
  opts <- doclr_options(to_formats = c("md", "json"), do_ocr = TRUE)

  expect_s3_class(opts, "doclr_options")
  expect_equal(opts$to_formats, list("md", "json"))
  expect_true(opts$do_ocr)
  expect_null(opts$table_mode)
})

test_that("doclr_options rejects an empty format list", {
  expect_error(doclr_options(to_formats = character(0)), class = "doclr_error_input")
})

test_that("doclr_options passes unknown fields through", {
  opts <- doclr_options(pdf_backend = "dlparse_v4")

  expect_equal(opts$pdf_backend, "dlparse_v4")
})

test_that("the source body wraps each URL as an http source", {
  body <- convert_source_body(
    c("https://a.test/x.pdf", "https://b.test/y.pdf"),
    doclr_options()
  )

  expect_length(body$sources, 2)
  expect_equal(body$sources[[1]], list(kind = "http", url = "https://a.test/x.pdf"))
  expect_equal(body$options$to_formats, list("md"))
})

test_that("the source body rejects local paths", {
  expect_error(
    convert_source_body("report.pdf", doclr_options()),
    class = "doclr_error_input"
  )
})

test_that("split_sources separates URLs from paths", {
  parts <- split_sources(c("https://a.test/x.pdf", "local.pdf"))

  expect_equal(parts$urls, "https://a.test/x.pdf")
  expect_equal(parts$paths, "local.pdf")
})

test_that("options are flattened into repeated form fields", {
  fields <- flatten_options(doclr_options(to_formats = c("md", "json"), do_ocr = TRUE))

  expect_equal(names(fields), c("to_formats", "to_formats", "do_ocr"))
  expect_equal(unlist(fields, use.names = FALSE), c("md", "json", "true"))
})

test_that("doclr_convert_source returns a document", {
  httr2::local_mocked_responses(function(req) {
    json_response(fake_convert_response())
  })

  doc <- doclr_convert_source(
    "https://a.test/x.pdf",
    client = doclr_client("http://localhost:5001")
  )

  expect_s3_class(doc, "doclr_document")
  expect_equal(doc$filename, "sample.pdf")
  expect_equal(doc$status, "success")
})

test_that("doclr_convert_file refuses files that do not exist", {
  expect_error(
    doclr_convert_file("no-such-file.pdf", client = doclr_client()),
    class = "doclr_error_input"
  )
})

test_that("doclr_convert_file uploads an existing file", {
  path <- withr::local_tempfile(fileext = ".txt")
  writeLines("hello", path)

  httr2::local_mocked_responses(function(req) {
    json_response(fake_convert_response())
  })

  doc <- doclr_convert_file(path, client = doclr_client("http://localhost:5001"))

  expect_s3_class(doc, "doclr_document")
})

test_that("server errors surface as doclr conditions", {
  httr2::local_mocked_responses(function(req) {
    json_response(list(detail = "unsupported format"), status = 422L)
  })

  expect_error(
    doclr_convert_source(
      "https://a.test/x.pdf",
      client = doclr_client("http://localhost:5001", max_tries = 1)
    ),
    class = "doclr_error_http"
  )
})
