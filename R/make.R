#' @title Hasty mode for the drake R package
#' @description Sacrifices reproducibility to gain speed.
#'   Targets are never cached and never up to date.
#'   Use at your own risk.
#' @export
#' @param config a `drake_config()` object
#' @examples
#' # See <https://github.com/wlandau/drake.hasty/blob/master/README.md>
#' # for examples.
hasty_make <- function(config) {
  warn_hasty(config)
  config <- prepare_config(config)
  if (config$jobs > 1L) {
    hasty_parallel(config)
  } else{
    hasty_loop(config)
  }
  invisible()
}

hasty_loop <- function(config) {
  targets <- igraph::topo_sort(config$schedule)$name
  for (target in targets) {
    drake:::console_target(target = target, config = config)
    config$eval[[target]] <- config$hasty_build(
      target = target,
      config = config
    )
  }
  invisible()
}

hasty_parallel <- function(config) {
  drake:::assert_pkg("clustermq", version = "0.8.5")
  config$queue <- drake:::new_priority_queue(
    config = config,
    jobs = config$jobs_preprocess
  )
  if (!config$queue$empty()) {
    config$workers <- clustermq::workers(
      n_jobs = config$jobs,
      template = config$template
    )
    drake:::cmq_set_common_data(config)
    config$counter <- new.env(parent = emptyenv())
    config$counter$remaining <- config$queue$size()
    hasty_master(config)
  }
  invisible()
}

hasty_master <- function(config) {
  on.exit(config$workers$finalize())
  while (config$counter$remaining > 0) {
    msg <- config$workers$receive_data()
    conclude_hasty_build(msg = msg, config = config)
    if (!identical(msg$token, "set_common_data_token")) {
      config$workers$send_common_data()
    } else if (!config$queue$empty()) {
      hasty_send_target(config)
    } else {
      config$workers$send_shutdown_worker()
    }
  }
  if (config$workers$cleanup()) {
    on.exit()
  }
}

hasty_send_target <- function(config) {
  target <- config$queue$pop0()
  if (!length(target)) {
    config$workers$send_wait() # nocov
    return() # nocov
  }
  drake:::console_target(target = target, config = config)
  deps <- hasty_deps_list(target = target, config = config)
  config$workers$send_call(
    expr = drake.hasty::remote_hasty_build(
      target = target,
      deps = deps,
      config = config
    ),
    env = list(target = target, deps = deps)
  )
}

hasty_deps_list <- function(target, config) {
  deps <- drake:::deps_graph(target, config$schedule)
  out <- lapply(
    X = deps,
    FUN = function(name) {
      config$eval[[name]]
    }
  )
  names(out) <- deps
  out
}

#' @title Build a target on a remote worker using "hasty" parallelism
#' @description For internal use only
#' @export
#' @keywords internal
#' @inheritParams hasty_build_default
#' @param deps named list of dependencies
remote_hasty_build <- function(target, deps = NULL, config) {
  drake:::do_prework(config = config, verbose_packages = FALSE)
  for (dep in names(deps)) {
    config$eval[[dep]] <- deps[[dep]]
  }
  value <- config$hasty_build(target = target, config = config)
  invisible(list(target = target, value = value))
}

conclude_hasty_build <- function(msg, config) {
  if (is.null(msg$result)) {
    return()
  }
  config$eval[[msg$result$target]] <- msg$result$value
  revdeps <- drake:::deps_graph(
    targets = msg$result$target,
    graph = config$schedule,
    reverse = TRUE
  )
  revdeps <- intersect(revdeps, config$queue$list())
  config$queue$decrease_key(targets = revdeps)
  config$counter$remaining <- config$counter$remaining - 1
}

warn_hasty <- function(config) {
  msg <- paste(
    "Hasty mode THROWS AWAY REPRODUCIBILITY to gain speed.",
    "drake's scientific claims at",
    "  https://ropensci.github.io/drake/#reproducibility-with-confidence", # nolint
    "  are NOT VALID IN HASTY MODE!",
    "Targets could be out of date even after make(),",
    "  and you have no way of knowing.",
    "USE AT YOUR OWN RISK!",
    "Details: https://github.com/wlandau/drake.hasty/blob/master/README.md", # nolint
    sep = "\n"
  )
  if (requireNamespace("crayon")) {
    msg <- crayon::red(msg)
  }
 warning(msg, call. = FALSE)
}
