# Submit a URL conversion as an asynchronous task

Submit a URL conversion as an asynchronous task

## Usage

``` r
doclr_convert_source_async(
  urls,
  options = doclr_options(),
  client = doclr_client()
)
```

## Arguments

- urls:

  Character vector of document URLs.

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
task <- doclr_convert_source_async("https://arxiv.org/pdf/2408.09869")
doclr_task_status(task)
}
```
