# Set up a local docling-serve server

Walks the fallback chain needed to get you a working server, asking
before it installs anything:

1.  If a server already answers on `port`, stop — there is nothing to
    do.

2.  If Podman or Docker is on the `PATH`, pull the image and run it.

3.  Otherwise offer to install Podman with the platform's package
    manager (Homebrew, winget, apt/dnf/pacman).

4.  If there is no container path at all but a Python interpreter is
    present, offer `pip install "docling-serve[ui]"` instead.

5.  If none of that applies — a locked-down machine with no WSL2 and no
    Python — prompt for the URL of a remote docling-serve instead of
    guessing.

This function is deliberately never called on load or attach: installing
system software is something you ask for explicitly.

## Usage

``` r
doclr_setup(
  engine = c("auto", "podman", "docker", "colima"),
  port = 5001,
  ui = FALSE,
  interactive = base::interactive()
)
```

## Arguments

- engine:

  Container engine to use. `"auto"` prefers Podman, then Docker, then
  Colima if you already have it.

- port:

  Port to publish the server on.

- ui:

  Start the bundled web UI. Off by default to keep the footprint small.

- interactive:

  Ask before installing anything. When `FALSE` nothing is installed, and
  the function reports what it would have done.

## Value

Invisibly, a
[`doclr_client()`](https://yves-amevoin.github.io/doclr/reference/doclr_client.md)
pointing at the server that is now available.

## Examples

``` r
if (FALSE) {
doclr_setup()
}
```
