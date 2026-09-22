# Submit a file conversion as an asynchronous task

Submit a file conversion as an asynchronous task

## Usage

``` r
doclr_convert_file_async(
  paths,
  options = doclr_options(),
  client = doclr_client()
)
```

## Arguments

- paths:

  Character vector of local file paths.

- options:

  A
  [`doclr_options()`](https://yves-amevoin.github.io/doclr/reference/doclr_options.md)
  object.

- client:

  A
  [`doclr_client()`](https://yves-amevoin.github.io/doclr/reference/doclr_client.md).

## Value

A
[doclr_task](https://yves-amevoin.github.io/doclr/reference/doclr_task.md)
object.

## Examples

``` r
if (FALSE) {
task <- doclr_convert_file_async("report.pdf")
doclr_task_status(task)
}
```
