# Fetch the result of a finished task

Calls `GET /v1/result/{task_id}`. The task must have reached the
`success` state; ask
[`doclr_task_status()`](https://yves-amevoin.github.io/doclr/reference/doclr_task_status.md)
first, or let
[`doclr_convert()`](https://yves-amevoin.github.io/doclr/reference/doclr_convert.md)
do the waiting for you.

## Usage

``` r
doclr_task_result(task, client = doclr_client())
```

## Arguments

- task:

  A
  [doclr_task](https://yves-amevoin.github.io/doclr/reference/doclr_task.md)
  object, or a task id string.

- client:

  A
  [`doclr_client()`](https://yves-amevoin.github.io/doclr/reference/doclr_client.md).
  Only used when `task` is an id string.

## Value

A
[doclr_document](https://yves-amevoin.github.io/doclr/reference/doclr_document.md)
object, or a list of them.

## Examples

``` r
if (FALSE) {
doclr_task_result(task)
}
```
