# Server management is tested entirely against mocked `Sys.which()` and
# `system2()` calls. Nothing here starts a container.

test_that("detect_engine prefers podman when both are installed", {
  local_mocked_bindings(
    Sys.which = function(names)
      stats::setNames(paste0("/usr/bin/", names), names),
    .package = "base"
  )

  expect_equal(detect_engine("auto"), "podman")
})

test_that("detect_engine falls back to docker", {
  local_mocked_bindings(
    Sys.which = function(names) {
      stats::setNames(ifelse(names == "docker", "/usr/bin/docker", ""), names)
    },
    .package = "base"
  )

  expect_equal(detect_engine("auto"), "docker")
})

test_that("detect_engine returns NULL when nothing is installed", {
  local_mocked_bindings(
    Sys.which = function(names) stats::setNames(rep("", length(names)), names),
    .package = "base"
  )

  expect_null(detect_engine("auto"))
})

test_that("colima is driven through the docker CLI", {
  local_mocked_bindings(
    Sys.which = function(names) {
      installed <- names %in% c("colima", "docker")
      stats::setNames(ifelse(installed, paste0("/usr/bin/", names), ""), names)
    },
    .package = "base"
  )

  expect_equal(detect_engine("colima"), "docker")
})

test_that("container_state reads the inspect output", {
  local_mocked_bindings(
    run_engine = function(engine, args, error = TRUE) "running"
  )

  expect_equal(container_state("podman", "doclr-server"), "running")
})

test_that("container_state is NULL for a container that does not exist", {
  local_mocked_bindings(
    run_engine = function(engine, args, error = TRUE) {
      structure(character(0), status = 125L)
    }
  )

  expect_null(container_state("podman", "doclr-server"))
})

test_that("run_engine turns a non-zero exit status into a doclr error", {
  local_mocked_bindings(
    system2 = function(...) structure("boom", status = 1L),
    .package = "base"
  )

  expect_error(run_engine("podman", "pull"), class = "doclr_error_engine")
})

test_that("doclr_server_start errors when no engine is available", {
  local_mocked_bindings(
    doclr_config = function() list(),
    detect_engine = function(engine = "auto") NULL
  )

  expect_error(doclr_server_start(), class = "doclr_error_setup")
})

test_that("doclr_server_start reuses a running container", {
  calls <- list()
  local_mocked_bindings(
    doclr_config = function() list(),
    detect_engine = function(engine = "auto") "podman",
    container_state = function(engine, name) "running",
    run_engine = function(engine, args, error = TRUE) {
      calls[[length(calls) + 1L]] <<- args
      invisible(character(0))
    },
    write_config = function(config) invisible(config),
    wait_for_health = function(port, timeout = 120) invisible(TRUE)
  )

  client <- doclr_server_start(port = 5001)

  expect_s3_class(client, "doclr_client")
  expect_length(calls, 0)
})

test_that("doclr_server_start pulls and runs a missing container", {
  calls <- list()
  local_mocked_bindings(
    doclr_config = function() list(),
    detect_engine = function(engine = "auto") "podman",
    container_state = function(engine, name) NULL,
    run_engine = function(engine, args, error = TRUE) {
      calls[[length(calls) + 1L]] <<- args
      invisible(character(0))
    },
    write_config = function(config) invisible(config),
    wait_for_health = function(port, timeout = 120) invisible(TRUE)
  )

  doclr_server_start(port = 5055)

  expect_equal(calls[[1]], c("pull", DOCLR_IMAGE))
  expect_true("5055:5001" %in% calls[[2]])
  expect_false(any(grepl("ENABLE_UI", calls[[2]])))
})

test_that("the ui flag adds the ui environment variable", {
  calls <- list()
  local_mocked_bindings(
    doclr_config = function() list(),
    detect_engine = function(engine = "auto") "podman",
    container_state = function(engine, name) NULL,
    run_engine = function(engine, args, error = TRUE) {
      calls[[length(calls) + 1L]] <<- args
      invisible(character(0))
    },
    write_config = function(config) invisible(config),
    wait_for_health = function(port, timeout = 120) invisible(TRUE)
  )

  doclr_server_start(ui = TRUE)

  expect_true(any(grepl("DOCLING_SERVE_ENABLE_UI=true", calls[[2]])))
})

test_that("doclr_server_stop is a no-op when the container is absent", {
  local_mocked_bindings(
    doclr_config = function()
      list(engine = "podman", container = "doclr-server"),
    container_state = function(engine, name) NULL
  )

  expect_false(doclr_server_stop())
})

test_that("doclr_server_stop stops an existing container", {
  stopped <- NULL
  local_mocked_bindings(
    doclr_config = function()
      list(engine = "podman", container = "doclr-server"),
    container_state = function(engine, name) "running",
    run_engine = function(engine, args, error = TRUE) {
      stopped <<- args
      invisible(character(0))
    }
  )

  expect_true(doclr_server_stop())
  expect_equal(stopped, c("stop", "doclr-server"))
})

test_that("doclr_server_status summarises the container", {
  local_mocked_bindings(
    doclr_config = function() {
      list(engine = "podman", container = "doclr-server", port = 5001)
    },
    container_state = function(engine, name) "exited",
    doclr_health = function(client = doclr_client()) FALSE
  )

  status <- doclr_server_status()

  expect_s3_class(status, "tbl_df")
  expect_equal(status$state, "exited")
  expect_false(status$healthy)
})

test_that("doclr_setup does nothing when a server already answers", {
  local_mocked_bindings(doclr_health = function(client = doclr_client()) TRUE)

  expect_s3_class(doclr_setup(interactive = FALSE), "doclr_client")
})

test_that("doclr_setup starts the server when an engine is present", {
  started <- FALSE
  local_mocked_bindings(
    doclr_health = function(client = doclr_client()) FALSE,
    detect_engine = function(engine = "auto") "podman",
    ensure_machine = function(engine, interactive = FALSE) invisible(TRUE),
    doclr_server_start = function(
      port = 5001,
      ui = FALSE,
      engine = NULL,
      name = DOCLR_CONTAINER
    ) {
      started <<- TRUE
      invisible(doclr_client(local_url(port)))
    }
  )

  doclr_setup(interactive = FALSE)

  expect_true(started)
})

test_that("doclr_setup suggests pip when only Python is available", {
  local_mocked_bindings(
    doclr_health = function(client = doclr_client()) FALSE,
    detect_engine = function(engine = "auto") NULL,
    offer_engine_install = function(interactive = FALSE) NULL,
    has_python = function() TRUE
  )

  expect_message(
    client <- doclr_setup(interactive = FALSE),
    "docling-serve"
  )
  expect_s3_class(client, "doclr_client")
})

test_that("doclr_setup errors rather than guessing on a locked-down machine", {
  local_mocked_bindings(
    doclr_health = function(client = doclr_client()) FALSE,
    detect_engine = function(engine = "auto") NULL,
    offer_engine_install = function(interactive = FALSE) NULL,
    has_python = function() FALSE
  )

  expect_error(doclr_setup(interactive = FALSE), class = "doclr_error_setup")
})

test_that("offer_engine_install installs nothing without consent", {
  local_mocked_bindings(
    detect_installer = function() {
      list(
        command = "brew",
        args = c("install", "podman"),
        label = "brew install podman"
      )
    },
    is_windows = function() FALSE,
    doclr_consent = function(question) FALSE
  )

  expect_null(offer_engine_install(interactive = TRUE))
})

test_that("offer_engine_install explains the WSL2 requirement on Windows", {
  local_mocked_bindings(
    detect_installer = function() {
      list(
        command = "winget",
        args = "x",
        label = "winget install RedHat.Podman"
      )
    },
    is_windows = function() TRUE,
    has_wsl2 = function() FALSE
  )

  expect_message(
    expect_null(offer_engine_install(interactive = TRUE)),
    "WSL2"
  )
})

test_that("the config round-trips through the config file", {
  withr::local_envvar(
    XDG_CONFIG_HOME = withr::local_tempdir(.local_envir = parent.frame())
  )
  config <- list(engine = "podman", container = "doclr-server", port = 5001)

  write_config(config)

  expect_equal(doclr_config()$engine, "podman")
  expect_equal(doclr_config()$port, 5001)
})

test_that("a missing config file reads as an empty list", {
  local_mocked_bindings(
    config_path = function() file.path(tempdir(), "no-such-config.json")
  )

  expect_equal(doclr_config(), list())
})

# Platform branch coverage --------------------------------------------------
#
# `doclr_setup()`'s macOS and Windows paths were only exercised manually
# against a real Podman machine (see .draft/plans/01-session-1-findings.md).
# These mock every OS check directly, so the per-platform branches below run
# on whatever OS the test suite happens to execute on.

test_that("detect_installer prefers Homebrew on macOS", {
  local_mocked_bindings(
    is_macos = function() TRUE,
    is_windows = function() FALSE,
    is_linux = function() FALSE
  )
  local_mocked_bindings(
    Sys.which = function(names) {
      stats::setNames(ifelse(names == "brew", "/usr/local/bin/brew", ""), names)
    },
    .package = "base"
  )

  installer <- detect_installer()

  expect_equal(installer$command, "brew")
  expect_equal(installer$args, c("install", "podman"))
})

test_that("detect_installer is NULL on macOS without Homebrew", {
  local_mocked_bindings(
    is_macos = function() TRUE,
    is_windows = function() FALSE,
    is_linux = function() FALSE
  )
  local_mocked_bindings(
    Sys.which = function(names) stats::setNames("", names),
    .package = "base"
  )

  expect_null(detect_installer())
})

test_that("detect_installer uses winget on Windows", {
  local_mocked_bindings(
    is_macos = function() FALSE,
    is_windows = function() TRUE,
    is_linux = function() FALSE
  )
  local_mocked_bindings(
    Sys.which = function(names) {
      stats::setNames(ifelse(names == "winget", "C:/winget.exe", ""), names)
    },
    .package = "base"
  )

  installer <- detect_installer()

  expect_equal(installer$command, "winget")
  expect_equal(installer$args, c("install", "-e", "--id", "RedHat.Podman"))
})

test_that("detect_installer is NULL on Windows without winget", {
  local_mocked_bindings(
    is_macos = function() FALSE,
    is_windows = function() TRUE,
    is_linux = function() FALSE
  )
  local_mocked_bindings(
    Sys.which = function(names) stats::setNames("", names),
    .package = "base"
  )

  expect_null(detect_installer())
})

test_that("detect_installer prefers apt on Linux", {
  local_mocked_bindings(
    is_macos = function() FALSE,
    is_windows = function() FALSE,
    is_linux = function() TRUE
  )
  local_mocked_bindings(
    Sys.which = function(names) {
      stats::setNames(ifelse(names == "apt", "/usr/bin/apt", ""), names)
    },
    .package = "base"
  )

  installer <- detect_installer()

  expect_equal(installer$command, "sudo")
  expect_equal(installer$args, c("apt", "install", "-y", "podman"))
})

test_that("detect_installer falls back to dnf on Linux when apt is missing", {
  local_mocked_bindings(
    is_macos = function() FALSE,
    is_windows = function() FALSE,
    is_linux = function() TRUE
  )
  local_mocked_bindings(
    Sys.which = function(names) {
      stats::setNames(ifelse(names == "dnf", "/usr/bin/dnf", ""), names)
    },
    .package = "base"
  )

  installer <- detect_installer()

  expect_equal(installer$command, "sudo")
  expect_equal(installer$args, c("dnf", "install", "-y", "podman"))
})

test_that("detect_installer falls back to pacman on Linux when apt and dnf are missing", {
  local_mocked_bindings(
    is_macos = function() FALSE,
    is_windows = function() FALSE,
    is_linux = function() TRUE
  )
  local_mocked_bindings(
    Sys.which = function(names) {
      stats::setNames(ifelse(names == "pacman", "/usr/bin/pacman", ""), names)
    },
    .package = "base"
  )

  installer <- detect_installer()

  expect_equal(installer$command, "sudo")
  expect_equal(installer$args, c("pacman", "-S", "--noconfirm", "podman"))
})

test_that("detect_installer is NULL on Linux with no known package manager", {
  local_mocked_bindings(
    is_macos = function() FALSE,
    is_windows = function() FALSE,
    is_linux = function() TRUE
  )
  local_mocked_bindings(
    Sys.which = function(names) stats::setNames("", names),
    .package = "base"
  )

  expect_null(detect_installer())
})

test_that("has_wsl2 is FALSE when the wsl command is not on PATH", {
  local_mocked_bindings(
    Sys.which = function(names) stats::setNames("", names),
    .package = "base"
  )

  expect_false(has_wsl2())
})

test_that("has_wsl2 is TRUE when wsl --status reports version 2", {
  local_mocked_bindings(
    Sys.which = function(names) stats::setNames("/usr/bin/wsl", names),
    .package = "base"
  )
  local_mocked_bindings(
    run_engine = function(engine, args, error = TRUE) {
      c("Default Distribution: Ubuntu", "Default Version: 2")
    }
  )

  expect_true(has_wsl2())
})

test_that("has_wsl2 is FALSE when wsl is present but reports no version 2", {
  local_mocked_bindings(
    Sys.which = function(names) stats::setNames("/usr/bin/wsl", names),
    .package = "base"
  )
  local_mocked_bindings(
    run_engine = function(engine, args, error = TRUE) {
      c("Default Distribution: Ubuntu", "Default Version: 1")
    }
  )

  expect_false(has_wsl2())
})

test_that("ensure_machine does nothing for a non-podman engine", {
  calls <- list()
  local_mocked_bindings(
    run_engine = function(engine, args, error = TRUE) {
      calls[[length(calls) + 1L]] <<- args
      invisible(character(0))
    }
  )

  expect_true(ensure_machine("docker"))
  expect_length(calls, 0)
})

test_that("ensure_machine does nothing on Linux", {
  calls <- list()
  local_mocked_bindings(
    is_linux = function() TRUE,
    run_engine = function(engine, args, error = TRUE) {
      calls[[length(calls) + 1L]] <<- args
      invisible(character(0))
    }
  )

  expect_true(ensure_machine("podman"))
  expect_length(calls, 0)
})

test_that("ensure_machine initialises and starts a fresh machine on macOS/Windows", {
  calls <- list()
  local_mocked_bindings(
    is_linux = function() FALSE,
    run_engine = function(engine, args, error = TRUE) {
      calls[[length(calls) + 1L]] <<- args
      if (identical(args, c("machine", "list", "--format", "{{.Name}}"))) {
        return(character(0))
      }
      if (identical(args, c("machine", "list", "--format", "{{.Running}}"))) {
        return("false")
      }
      invisible(character(0))
    }
  )

  ensure_machine("podman")

  expect_true(any(vapply(calls, identical, logical(1), c("machine", "init"))))
  expect_true(any(vapply(calls, identical, logical(1), c("machine", "start"))))
})

test_that("ensure_machine skips init and start when a machine is already running", {
  calls <- list()
  local_mocked_bindings(
    is_linux = function() FALSE,
    run_engine = function(engine, args, error = TRUE) {
      calls[[length(calls) + 1L]] <<- args
      if (identical(args, c("machine", "list", "--format", "{{.Name}}"))) {
        return("podman-machine-default")
      }
      if (identical(args, c("machine", "list", "--format", "{{.Running}}"))) {
        return("true")
      }
      invisible(character(0))
    }
  )

  ensure_machine("podman")

  expect_false(any(vapply(calls, identical, logical(1), c("machine", "init"))))
  expect_false(any(vapply(calls, identical, logical(1), c("machine", "start"))))
})
