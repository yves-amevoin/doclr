# Wait for a task to finish

Wait for a task to finish

## Usage

``` r
doclr_wait(
  task,
  client = doclr_client(),
  poll_interval = 2,
  timeout = 600,
  quiet = !interactive()
)
```

## Arguments

- task:

  A
  [doclr_task](https://yves-amevoin.github.io/doclr/reference/doclr_task.md)
  object, or a task id string.

- client:

  A
  [`doclr_client()`](https://yves-amevoin.github.io/doclr/reference/doclr_client.md).

- poll_interval:

  Seconds between status checks.

- timeout:

  Give up after this many seconds.

- quiet:

  Suppress the progress spinner.

## Value

A
[doclr_document](https://yves-amevoin.github.io/doclr/reference/doclr_document.md)
object, or a list of them.

## Examples

``` r
if (FALSE) {
task <- doclr_convert_file_async("report.pdf")
doclr_wait(task)
}
```
