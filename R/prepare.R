prepare_config <- function(config) {
  if (is.null(config$plan)) {
    stop("Hasty mode needs a drake plan", call. = FALSE)
  }
  if (is.null(config$schedule)) {
    stop("Hasty mode needs a job schedule (igraph)", call. = FALSE)
  }
  if (is.null(config$envir)) {
    stop("Hasty mode needs an environment", call. = FALSE)
  }
  if (is.null(config$eval)) {
    config$eval <- new.env(parent = config$envir)
  }
  if (is.null(config$hasty_build)) {
    config$hasty_build <- hasty_build_default
  }
  if (is.null(config$jobs)) {
    config$jobs <- 1L
  }
  if (is.null(config$jobs_preprocess)) {
    config$jobs_preprocess <- 1L
  }
  if (is.null(config$verbose)) {
    config$verbose <- 1L
  }
  if (is.null(config$prework)) {
    config$prework <- drake:::add_packages_to_prework(
      rev(.packages()),
      NULL
    )
  }
  config$skip_imports <- TRUE
  config$skip_safety_checks <- TRUE
  config$skip_targets <- FALSE
  config$commands <- prepare_commands(config)
  config
}

prepare_commands <- function(config) {
  commands <- config$plan$command
  if (is.character(commands)) {
    commands <- lapply(
      X = commands,
      FUN = function(command) {
        parse(text = command, keep.source = FALSE)[[1]]
      }
    )
  }
  names(commands) <- config$plan$target
  list2env(commands, parent = emptyenv())
}
