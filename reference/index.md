# Package index

## Connecting

Point doclr at a docling-serve instance.

- [`doclr_client()`](https://yves-amevoin.github.io/doclr/reference/doclr_client.md)
  : Create a connection to a docling-serve server
- [`is_doclr_client()`](https://yves-amevoin.github.io/doclr/reference/is_doclr_client.md)
  : Test whether an object is a doclr client
- [`doclr_health()`](https://yves-amevoin.github.io/doclr/reference/doclr_health.md)
  : Check that a docling-serve server is reachable

## Converting

Submit documents and collect the results.

- [`doclr_convert()`](https://yves-amevoin.github.io/doclr/reference/doclr_convert.md)
  : Convert a document, waiting for the result
- [`doclr_options()`](https://yves-amevoin.github.io/doclr/reference/doclr_options.md)
  : Conversion options accepted by docling-serve
- [`doclr_convert_source()`](https://yves-amevoin.github.io/doclr/reference/doclr_convert_source.md)
  : Convert documents given by URL
- [`doclr_convert_file()`](https://yves-amevoin.github.io/doclr/reference/doclr_convert_file.md)
  : Convert documents by uploading local files
- [`doclr_convert_source_async()`](https://yves-amevoin.github.io/doclr/reference/doclr_convert_source_async.md)
  : Submit a URL conversion as an asynchronous task
- [`doclr_convert_file_async()`](https://yves-amevoin.github.io/doclr/reference/doclr_convert_file_async.md)
  : Submit a file conversion as an asynchronous task

## Asynchronous tasks

- [`doclr_task`](https://yves-amevoin.github.io/doclr/reference/doclr_task.md)
  : An asynchronous docling-serve conversion task
- [`doclr_task_status()`](https://yves-amevoin.github.io/doclr/reference/doclr_task_status.md)
  : Poll the status of an asynchronous task
- [`doclr_task_result()`](https://yves-amevoin.github.io/doclr/reference/doclr_task_result.md)
  : Fetch the result of a finished task
- [`doclr_wait()`](https://yves-amevoin.github.io/doclr/reference/doclr_wait.md)
  : Wait for a task to finish

## Working with documents

- [`doclr_document`](https://yves-amevoin.github.io/doclr/reference/doclr_document.md)
  : A converted docling document
- [`is_doclr_document()`](https://yves-amevoin.github.io/doclr/reference/is_doclr_document.md)
  : Test whether an object is a converted document
- [`as_markdown()`](https://yves-amevoin.github.io/doclr/reference/as_markdown.md)
  : Render a converted document as Markdown
- [`as_text()`](https://yves-amevoin.github.io/doclr/reference/as_text.md)
  : Render a converted document as plain text
- [`as_html()`](https://yves-amevoin.github.io/doclr/reference/as_html.md)
  : Render a converted document as HTML
- [`as_json()`](https://yves-amevoin.github.io/doclr/reference/as_json.md)
  : Extract the structured JSON representation of a document
- [`as_doctags()`](https://yves-amevoin.github.io/doclr/reference/as_doctags.md)
  : Render a converted document as DocTags

## Local server

Provision and manage a docling-serve container.

- [`doclr_setup()`](https://yves-amevoin.github.io/doclr/reference/doclr_setup.md)
  : Set up a local docling-serve server
- [`doclr_server_start()`](https://yves-amevoin.github.io/doclr/reference/doclr_server_start.md)
  : Start the managed docling-serve container
- [`doclr_server_stop()`](https://yves-amevoin.github.io/doclr/reference/doclr_server_stop.md)
  : Stop the managed docling-serve container
- [`doclr_server_status()`](https://yves-amevoin.github.io/doclr/reference/doclr_server_status.md)
  : Report on the managed docling-serve container
