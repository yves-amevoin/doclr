# Check that a docling-serve server is reachable

Check that a docling-serve server is reachable

## Usage

``` r
doclr_health(client = doclr_client())
```

## Arguments

- client:

  A
  [`doclr_client()`](https://yves-amevoin.github.io/doclr/reference/doclr_client.md).

## Value

`TRUE` if the server answers its health endpoint, otherwise `FALSE`.

## Examples

``` r
if (FALSE) {
doclr_health(doclr_client())
}
```
