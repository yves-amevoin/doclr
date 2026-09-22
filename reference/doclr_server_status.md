# Report on the managed docling-serve container

Report on the managed docling-serve container

## Usage

``` r
doclr_server_status(engine = NULL, name = NULL, port = NULL)
```

## Arguments

- engine:

  Container engine to use. `"auto"` prefers Podman, then Docker, then
  Colima if you already have it.

- name:

  Container name.

- port:

  Port to publish the server on.

## Value

A one-row tibble with the engine, container name, port, container state
and whether the server answers its health endpoint.

## Examples

``` r
if (FALSE) {
doclr_server_status()
}
```
