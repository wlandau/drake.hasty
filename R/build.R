#' @title Build a target in hasty mode.
#' @description Runs really fast.
#' @export
#' @param target character, name of the target to build
#' @param config a `drake_config()` object
hasty_build_default <- function(target, config) {
  tidy_expr <- eval(
    expr = config$layout[[target]]$command_build,
    envir = config$eval
  )
  eval(expr = tidy_expr, envir = config$eval)
}

#' @title Build a target in hasty mode with storage.
#' @description Builds the target, caches it, and does nothing else.
#' @export
#' @param target character, name of the target to build
#' @param config a `drake_config()` object
hasty_build_store <- function(target, config) {
  tidy_expr <- eval(
    expr = config$layout[[target]]$command_build,
    envir = config$eval
  )
  value <- eval(expr = tidy_expr, envir = config$eval)
  config$cache$set(key = target, value = value)
  value
}
