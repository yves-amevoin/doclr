# Start the managed docling-serve container

Reuses the container recorded by a previous
[`doclr_setup()`](https://yves-amevoin.github.io/doclr/reference/doclr_setup.md)
when there is one, and creates it otherwise. The chosen engine,
container name and port are written to the user config directory so that
[`doclr_server_stop()`](https://yves-amevoin.github.io/doclr/reference/doclr_server_stop.md)
and
[`doclr_server_status()`](https://yves-amevoin.github.io/doclr/reference/doclr_server_status.md)
can find them again.

## Usage

``` r
doclr_server_start(
  port = 5001,
  ui = FALSE,
  engine = NULL,
  name = DOCLR_CONTAINER
)
```

## Arguments

- port:

  Port to publish the server on.

- ui:

  Start the bundled web UI. Off by default to keep the footprint small.

- engine:

  Container engine to use. `"auto"` prefers Podman, then Docker, then
  Colima if you already have it.

- name:

  Container name.

## Value

Invisibly, a
[`doclr_client()`](https://yves-amevoin.github.io/doclr/reference/doclr_client.md)
for the running server.

## Examples

``` r
if (FALSE) {
doclr_server_start()
}
```
