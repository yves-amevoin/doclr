# Fixtures shared by the mocked tests. Nothing here touches the network.

fake_document <- function(filename = "sample.pdf") {
  list(
    filename = filename,
    md_content = "# Sample\n\nHello world.",
    text_content = "Sample\n\nHello world.",
    html_content = "<h1>Sample</h1>",
    json_content = '{"name":"sample"}',
    doctags_content = "<doctag>sample</doctag>"
  )
}

fake_convert_response <- function(status = "success") {
  list(
    document = fake_document(),
    status = status,
    processing_time = 1.25,
    errors = list()
  )
}

# Build an httr2 response carrying `body` as JSON.
json_response <- function(body, status = 200L, url = "http://localhost:5001") {
  httr2::response(
    status_code = status,
    url = url,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(jsonlite::toJSON(body, auto_unbox = TRUE, null = "null"))
  )
}

# Replay a fixed sequence of responses, one per request performed.
mock_sequence <- function(responses) {
  index <- 0L
  function(req) {
    index <<- index + 1L
    responses[[min(index, length(responses))]]
  }
}
