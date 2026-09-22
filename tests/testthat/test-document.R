test_that("a document exposes every format the server returned", {
  doc <- new_document_result(fake_convert_response())

  expect_true(is_doclr_document(doc))
  expect_equal(as_markdown(doc), "# Sample\n\nHello world.")
  expect_equal(as_text(doc), "Sample\n\nHello world.")
  expect_equal(as_html(doc), "<h1>Sample</h1>")
  expect_equal(as_doctags(doc), "<doctag>sample</doctag>")
})

test_that("as_json parses a JSON string payload", {
  doc <- new_document_result(fake_convert_response())

  expect_equal(as_json(doc), list(name = "sample"))
})

test_that("asking for a format that was not produced is an error", {
  response <- fake_convert_response()
  response$document$html_content <- NULL
  doc <- new_document_result(response)

  expect_error(as_html(doc), class = "doclr_error_format")
})

test_that("the as_* generics reject non-documents", {
  expect_error(as_markdown("not a document"), class = "doclr_error_input")
})

test_that("a multi-document response yields a list of documents", {
  response <- list(
    documents = list(fake_document("a.pdf"), fake_document("b.pdf")),
    status = "success"
  )

  docs <- new_document_result(response)

  expect_type(docs, "list")
  expect_length(docs, 2)
  expect_equal(docs[[2]]$filename, "b.pdf")
})

test_that("a single-document response is not wrapped in a list", {
  response <- list(documents = list(fake_document("a.pdf")), status = "success")

  expect_s3_class(new_document_result(response), "doclr_document")
})

test_that("an empty response still gives a usable document", {
  doc <- new_document_result(list(status = "failure"))

  expect_s3_class(doc, "doclr_document")
  expect_length(doc$content, 0)
  expect_error(as_markdown(doc), class = "doclr_error_format")
})

test_that("documents print without erroring", {
  doc <- new_document_result(fake_convert_response())

  expect_no_error(print(doc))
  expect_identical(print(doc), doc)
})
