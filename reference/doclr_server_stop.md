# Stop the managed docling-serve container

Stop the managed docling-serve container

## Usage

``` r
doclr_server_stop(engine = NULL, name = NULL)
```

## Arguments

- engine:

  Container engine to use. `"auto"` prefers Podman, then Docker, then
  Colima if you already have it.

- name:

  Container name.

## Value

Invisibly, `TRUE` if a container was stopped, `FALSE` otherwise.

## Examples

``` r
if (FALSE) {
doclr_server_stop()
}
```
