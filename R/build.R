#' @title Build a target in hasty mode.
#' @description Runs really fast.
#' @export
#' @param target character, name of the target to build
#' @param config a `drake_config()` object
hasty_build_default <- function(target, config) {
  eval(expr = config$commands[[target]], envir = config$eval)
}

#' @title Build a target in hasty mode with storage.
#' @description Builds the target, caches it, and does nothing else.
#' @export
#' @inheritParams hasty_build_default
hasty_build_store <- function(target, config) {
  value <- eval(expr = config$commands[[target]], envir = config$eval)
  config$cache$set(key = target, value = value)
  value
}
