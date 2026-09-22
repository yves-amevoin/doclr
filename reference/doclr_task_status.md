# Poll the status of an asynchronous task

Calls `GET /v1/status/poll/{task_id}`. With `wait` greater than zero the
server holds the connection open until the status changes or the wait
elapses, which is cheaper than tight client-side polling.

## Usage

``` r
doclr_task_status(task, wait = 0, client = doclr_client())
```

## Arguments

- task:

  A
  [doclr_task](https://yves-amevoin.github.io/doclr/reference/doclr_task.md)
  object, or a task id string.

- wait:

  Seconds the server may hold the request open before answering.

- client:

  A
  [`doclr_client()`](https://yves-amevoin.github.io/doclr/reference/doclr_client.md).
  Only used when `task` is an id string.

## Value

A one-row tibble with `task_id`, `status` and `position`.

## Examples

``` r
if (FALSE) {
task <- doclr_convert_source_async("https://arxiv.org/pdf/2408.09869")
doclr_task_status(task)
}
```
