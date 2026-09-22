#' Default name of the managed container
#'
#' @noRd
DOCLR_CONTAINER <- "doclr-server"

#' Set up a local docling-serve server
#'
#' @description
#' Walks the fallback chain needed to get you a working server, asking before
#' it installs anything:
#'
#' 1. If a server already answers on `port`, stop — there is nothing to do.
#' 2. If Podman or Docker is on the `PATH`, pull the image and run it.
#' 3. Otherwise offer to install Podman with the platform's package manager
#'    (Homebrew, winget, apt/dnf/pacman).
#' 4. If there is no container path at all but a Python interpreter is
#'    present, offer `pip install "docling-serve[ui]"` instead.
#' 5. If none of that applies — a locked-down machine with no WSL2 and no
#'    Python — prompt for the URL of a remote docling-serve instead of
#'    guessing.
#'
#' This function is deliberately never called on load or attach: installing
#' system software is something you ask for explicitly.
#'
#' @param engine Container engine to use. `"auto"` prefers Podman, then
#'   Docker, then Colima if you already have it.
#' @param port Port to publish the server on.
#' @param ui Start the bundled web UI. Off by default to keep the footprint
#'   small.
#' @param interactive Ask before installing anything. When `FALSE` nothing is
#'   installed, and the function reports what it would have done.
#'
#' @return Invisibly, a [doclr_client()] pointing at the server that is now
#'   available.
#' @export
#'
#' @examplesIf FALSE
#' doclr_setup()
doclr_setup <- function(
  engine = c("auto", "podman", "docker", "colima"),
  port = 5001,
  ui = FALSE,
  interactive = base::interactive()
) {
  engine <- rlang::arg_match(engine)
  url <- local_url(port)

  if (doclr_health(doclr_client(url))) {
    cli::cli_alert_success(
      "A docling-serve server already answers at {.url {url}}."
    )
    return(invisible(doclr_client(url)))
  }

  runtime <- detect_engine(engine)

  if (!is.null(runtime)) {
    cli::cli_alert_info("Using {.strong {runtime}} as the container engine.")
    ensure_machine(runtime, interactive = interactive)
    doclr_server_start(port = port, ui = ui, engine = runtime)
    return(invisible(doclr_client(url)))
  }

  installed <- offer_engine_install(interactive = interactive)
  if (!is.null(installed)) {
    ensure_machine(installed, interactive = interactive)
    doclr_server_start(port = port, ui = ui, engine = installed)
    return(invisible(doclr_client(url)))
  }

  if (has_python()) {
    cli::cli_bullets(c(
      "i" = "No container engine is available, but Python is.",
      "*" = "Install the server yourself with:",
      " " = "{.code pip install \"docling-serve[ui]\"}",
      " " = "{.code docling-serve run --port {port}}"
    ))
    return(invisible(doclr_client(url)))
  }

  remote_url <- prompt_remote_url(interactive = interactive)
  invisible(doclr_client(remote_url))
}

#' Start the managed docling-serve container
#'
#' @description
#' Reuses the container recorded by a previous [doclr_setup()] when there is
#' one, and creates it otherwise. The chosen engine, container name and port
#' are written to the user config directory so that
#' [doclr_server_stop()] and [doclr_server_status()] can find them again.
#'
#' @inheritParams doclr_setup
#' @param name Container name.
#'
#' @return Invisibly, a [doclr_client()] for the running server.
#' @export
#'
#' @examplesIf FALSE
#' doclr_server_start()
doclr_server_start <- function(
  port = 5001,
  ui = FALSE,
  engine = NULL,
  name = DOCLR_CONTAINER
) {
  config <- doclr_config()
  engine <- engine %||% config$engine %||% detect_engine("auto")

  if (is.null(engine)) {
    doclr_abort(
      c(
        "No container engine found.",
        "i" = "Run {.fun doclr_setup} to install one, or point
               {.fun doclr_client} at a remote server."
      ),
      class = "setup"
    )
  }

  existing <- container_state(engine, name)

  if (identical(existing, "running")) {
    cli::cli_alert_success("Container {.val {name}} is already running.")
  } else if (!is.null(existing)) {
    cli::cli_alert_info("Starting existing container {.val {name}}.")
    run_engine(engine, c("start", name))
  } else {
    cli::cli_alert_info("Pulling {.val {DOCLR_IMAGE}} (this can take a while).")
    run_engine(engine, c("pull", DOCLR_IMAGE))

    args <- c(
      "run",
      "-d",
      "--name",
      name,
      "-p",
      paste0(port, ":5001")
    )
    if (ui) {
      args <- c(args, "-e", "DOCLING_SERVE_ENABLE_UI=true")
    }
    run_engine(engine, c(args, DOCLR_IMAGE))
  }

  write_config(list(engine = engine, container = name, port = port))
  wait_for_health(port)

  invisible(doclr_client(local_url(port)))
}

#' Stop the managed docling-serve container
#'
#' @inheritParams doclr_server_start
#'
#' @return Invisibly, `TRUE` if a container was stopped, `FALSE` otherwise.
#' @export
#'
#' @examplesIf FALSE
#' doclr_server_stop()
doclr_server_stop <- function(engine = NULL, name = NULL) {
  config <- doclr_config()
  engine <- engine %||% config$engine %||% detect_engine("auto")
  name <- name %||% config$container %||% DOCLR_CONTAINER

  if (is.null(engine)) {
    cli::cli_alert_warning("No container engine found; nothing to stop.")
    return(invisible(FALSE))
  }

  if (is.null(container_state(engine, name))) {
    cli::cli_alert_info("No container named {.val {name}}.")
    return(invisible(FALSE))
  }

  run_engine(engine, c("stop", name))
  cli::cli_alert_success("Stopped {.val {name}}.")
  invisible(TRUE)
}

#' Report on the managed docling-serve container
#'
#' @inheritParams doclr_server_start
#'
#' @return A one-row tibble with the engine, container name, port, container
#'   state and whether the server answers its health endpoint.
#' @export
#'
#' @examplesIf FALSE
#' doclr_server_status()
doclr_server_status <- function(engine = NULL, name = NULL, port = NULL) {
  config <- doclr_config()
  engine <- engine %||% config$engine %||% detect_engine("auto")
  name <- name %||% config$container %||% DOCLR_CONTAINER
  port <- port %||% config$port %||% 5001

  state <- if (is.null(engine)) NA_character_ else container_state(engine, name)

  tibble::tibble(
    engine = as.character(engine %||% NA_character_),
    container = name,
    port = as.integer(port),
    state = as.character(state %||% "absent"),
    healthy = doclr_health(doclr_client(local_url(port)))
  )
}

# Engine detection and execution ----

#' Find a usable container engine
#'
#' @param engine One of `"auto"`, `"podman"`, `"docker"`, `"colima"`.
#'
#' @return The engine command name, or `NULL` when none is available.
#' @noRd
detect_engine <- function(engine = "auto") {
  candidates <- if (identical(engine, "auto")) {
    c("podman", "docker")
  } else if (identical(engine, "colima")) {
    # Colima provides a Docker daemon; the CLI you drive it with is docker.
    if (nzchar(Sys.which("colima"))) "docker" else character(0)
  } else {
    engine
  }

  found <- candidates[nzchar(Sys.which(candidates))]
  if (length(found) == 0L) NULL else found[[1L]]
}

#' Run a container engine command
#'
#' @param engine Engine command name.
#' @param args Character vector of arguments.
#' @param error Whether a non-zero exit status is an error.
#'
#' @return The captured standard output, invisibly.
#' @noRd
run_engine <- function(engine, args, error = TRUE) {
  output <- suppressWarnings(
    system2(engine, args, stdout = TRUE, stderr = TRUE)
  )
  status <- attr(output, "status") %||% 0L

  if (error && !identical(as.integer(status), 0L)) {
    doclr_abort(
      c(
        "{.code {engine} {paste(args, collapse = ' ')}} failed.",
        "x" = "{paste(output, collapse = '\n')}"
      ),
      class = "engine",
      status = status
    )
  }

  invisible(output)
}

#' Inspect the state of a container
#'
#' @param engine Engine command name.
#' @param name Container name.
#'
#' @return `"running"`, another state string, or `NULL` when the container
#'   does not exist.
#' @noRd
container_state <- function(engine, name) {
  output <- run_engine(
    engine,
    c("inspect", "--format", "{{.State.Status}}", name),
    error = FALSE
  )
  status <- attr(output, "status") %||% 0L

  if (!identical(as.integer(status), 0L) || length(output) == 0L) {
    return(NULL)
  }

  trimws(output[[length(output)]])
}

#' Start the Podman virtual machine on macOS and Windows
#'
#' Linux runs containers natively, so nothing happens there.
#'
#' @param engine Engine command name.
#' @param interactive Whether we may act without further prompting.
#'
#' @return Invisibly, `TRUE` when a machine was started or none was needed.
#' @noRd
ensure_machine <- function(engine, interactive = base::interactive()) {
  if (!identical(engine, "podman") || is_linux()) {
    return(invisible(TRUE))
  }

  listed <- run_engine(
    "podman",
    c("machine", "list", "--format", "{{.Name}}"),
    error = FALSE
  )
  if (length(listed) == 0L || !any(nzchar(trimws(listed)))) {
    cli::cli_alert_info("Initialising the Podman machine.")
    run_engine("podman", c("machine", "init"))
  }

  running <- run_engine(
    "podman",
    c("machine", "list", "--format", "{{.Running}}"),
    error = FALSE
  )
  if (!any(grepl("true", running, ignore.case = TRUE))) {
    cli::cli_alert_info("Starting the Podman machine.")
    run_engine("podman", c("machine", "start"))
  }

  invisible(TRUE)
}

#' Offer to install a container engine
#'
#' @param interactive Whether consent may be asked for.
#'
#' @return The engine command name once installed, or `NULL`.
#' @noRd
offer_engine_install <- function(interactive = base::interactive()) {
  installer <- detect_installer()

  if (is.null(installer)) {
    cli::cli_alert_warning(
      "No container engine and no package manager to install one with."
    )
    return(NULL)
  }

  if (is_windows() && !has_wsl2()) {
    cli::cli_bullets(c(
      "!" = "Podman on Windows needs WSL2, which is not enabled here.",
      "i" = "Enable it with {.code wsl --install} from an elevated prompt,
             then run {.fun doclr_setup} again."
    ))
    return(NULL)
  }

  if (!interactive) {
    cli::cli_bullets(c(
      "i" = "Podman is not installed. Install it with:",
      " " = "{.code {installer$label}}"
    ))
    return(NULL)
  }

  consent <- doclr_consent(
    paste0("Install Podman with `", installer$label, "`?")
  )
  if (!consent) {
    cli::cli_alert_info("Nothing installed.")
    return(NULL)
  }

  run_engine(installer$command, installer$args)

  if (nzchar(Sys.which("podman"))) "podman" else NULL
}

#' Work out which package manager can install Podman
#'
#' @return A list with `command`, `args` and a human-readable `label`, or
#'   `NULL`.
#' @noRd
detect_installer <- function() {
  if (is_macos() && nzchar(Sys.which("brew"))) {
    return(list(
      command = "brew",
      args = c("install", "podman"),
      label = "brew install podman"
    ))
  }

  if (is_windows() && nzchar(Sys.which("winget"))) {
    return(list(
      command = "winget",
      args = c("install", "-e", "--id", "RedHat.Podman"),
      label = "winget install RedHat.Podman"
    ))
  }

  if (is_linux()) {
    managers <- list(
      apt = c("install", "-y", "podman"),
      dnf = c("install", "-y", "podman"),
      pacman = c("-S", "--noconfirm", "podman")
    )
    for (manager in names(managers)) {
      if (nzchar(Sys.which(manager))) {
        return(list(
          command = "sudo",
          args = c(manager, managers[[manager]]),
          label = paste("sudo", manager, "install podman")
        ))
      }
    }
  }

  NULL
}

#' Ask for the URL of a remote docling-serve
#'
#' @param interactive Whether a prompt may be shown.
#'
#' @return A URL string.
#' @noRd
prompt_remote_url <- function(interactive = base::interactive()) {
  cli::cli_bullets(c(
    "!" = "No container engine and no Python interpreter were found.",
    "i" = "Point doclr at a docling-serve someone else is running."
  ))

  if (!interactive) {
    doclr_abort(
      c(
        "Cannot provision a local server here.",
        "i" = "Use {.code doclr_client(url = \"https://your-server\")}."
      ),
      class = "setup"
    )
  }

  answer <- trimws(readline("docling-serve URL: "))
  if (!nzchar(answer)) {
    doclr_abort(
      c(
        "No URL supplied.",
        "i" = "Use {.code doclr_client(url = \"https://your-server\")}."
      ),
      class = "setup"
    )
  }

  answer
}

#' Ask the user to confirm an action
#'
#' @param question Question to put to the user.
#'
#' @return `TRUE` when the user consents.
#' @noRd
doclr_consent <- function(question) {
  cli::cli_text(question)
  answer <- tolower(trimws(readline("[y/N]: ")))
  answer %in% c("y", "yes")
}

#' Wait until the local server answers
#'
#' @param port Port the server is published on.
#' @param timeout Seconds to wait.
#'
#' @return Invisibly, `TRUE`.
#' @noRd
wait_for_health <- function(port, timeout = 120) {
  url <- local_url(port)
  client <- doclr_client(url)
  deadline <- Sys.time() + timeout

  cli::cli_progress_step("Waiting for {.url {url}}")
  repeat {
    if (doclr_health(client)) {
      cli::cli_progress_done()
      cli::cli_alert_success("docling-serve is ready at {.url {url}}.")
      return(invisible(TRUE))
    }
    if (Sys.time() > deadline) {
      doclr_abort(
        c(
          "The server did not become healthy within {timeout}s.",
          "i" = "Check the container logs for details."
        ),
        class = "setup"
      )
    }
    Sys.sleep(2)
  }
}

# Configuration persistence ----

#' Path to the persisted doclr configuration
#'
#' @return A file path.
#' @noRd
config_path <- function() {
  file.path(rappdirs::user_config_dir("doclr"), "server.json")
}

#' Read the persisted configuration
#'
#' @return A named list; empty when nothing has been saved.
#' @noRd
doclr_config <- function() {
  path <- config_path()
  if (!file.exists(path)) {
    return(list())
  }

  tryCatch(
    jsonlite::read_json(path, simplifyVector = TRUE),
    error = function(e) list()
  )
}

#' Persist the configuration
#'
#' @param config A named list.
#'
#' @return Invisibly, the path written to.
#' @noRd
write_config <- function(config) {
  path <- config_path()
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(config, path, auto_unbox = TRUE)
  invisible(path)
}

# Platform helpers ----

#' Local server URL for a port
#'
#' @param port Port number.
#'
#' @return A URL string.
#' @noRd
local_url <- function(port) {
  paste0("http://localhost:", port)
}

#' @noRd
is_macos <- function() {
  identical(tolower(Sys.info()[["sysname"]]), "darwin")
}

#' @noRd
is_windows <- function() {
  identical(.Platform$OS.type, "windows")
}

#' @noRd
is_linux <- function() {
  identical(tolower(Sys.info()[["sysname"]]), "linux")
}

#' Is a real Python interpreter available?
#'
#' @return `TRUE` when `python`, `python3` or `pip` resolves.
#' @noRd
has_python <- function() {
  any(nzchar(Sys.which(c("python3", "python", "pip3", "pip"))))
}

#' Is WSL2 available on this Windows machine?
#'
#' @return `TRUE` when `wsl --status` reports a version 2 default.
#' @noRd
has_wsl2 <- function() {
  if (!nzchar(Sys.which("wsl"))) {
    return(FALSE)
  }

  output <- run_engine("wsl", c("--status"), error = FALSE)
  any(grepl("2", output, fixed = TRUE))
}
