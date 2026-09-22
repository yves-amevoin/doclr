# Test whether an object is a doclr client

Test whether an object is a doclr client

## Usage

``` r
is_doclr_client(x)
```

## Arguments

- x:

  An object.

## Value

`TRUE` if `x` is a `doclr_client`, otherwise `FALSE`.

## Examples

``` r
is_doclr_client(doclr_client())
#> [1] TRUE
is_doclr_client(1)
#> [1] FALSE
```
