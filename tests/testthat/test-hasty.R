context("hasty mode")

test_that("default build function", {
  dir <- tempfile()
  dir.create(dir)
  withr::with_dir(dir, {
    load_mtcars_example()
    my_plan$command[my_plan$target == "report"][[1]] <-
      quote(saveRDS(coef_regression2_large, file = file_out("coef.rds")))
    options(clustermq.scheduler = "multicore")
    config <- drake_config(my_plan)
    for (jobs in 1:2) {
      if (jobs > 1) {
        skip_on_os("windows")
        skip_if_not_installed("clustermq")
        if ("package:clustermq" %in% search()) {
          detach("package:clustermq", unload = TRUE) # nolint
        }
      }
      config$jobs <- jobs
      expect_false(file.exists("coef.rds"))
      expect_warning(
        hasty_make(config = config),
        regexp = "USE AT YOUR OWN RISK"
      )
      expect_true(file.exists("coef.rds"))
      expect_equal(length(intersect(my_plan$target, cached())), 0)
      unlink("coef.rds")
      expect_false(file.exists("coef.rds"))
    }
    if ("package:clustermq" %in% search()) {
      detach("package:clustermq", unload = TRUE) # nolint
    }
  })
})

test_that("hasty_build_store()", {
  dir <- tempfile()
  dir.create(dir)
  withr::with_dir(dir, {
    load_mtcars_example()
    options(clustermq.scheduler = "multicore")
    for (jobs in 1:2) {
      config <- drake_config(my_plan)
      config$hasty_build <- hasty_build_store
      if (jobs > 1) {
        skip_on_os("windows")
        skip_if_not_installed("clustermq")
        if ("package:clustermq" %in% search()) {
          detach("package:clustermq", unload = TRUE) # nolint
        }
      }
      config$jobs <- jobs
      expect_warning(
        hasty_make(config = config),
        regexp = "USE AT YOUR OWN RISK"
      )
      expect_true(is.data.frame(config$cache$get("small")))
      expect_true(config$cache$exists("report"))
      clean(destroy = TRUE)
      expect_false(config$cache$exists("small"))
      expect_false(config$cache$exists("report"))
    }
    if ("package:clustermq" %in% search()) {
      detach("package:clustermq", unload = TRUE) # nolint
    }
  })
})

test_that("custom build function", {
  dir <- tempfile()
  dir.create(dir)
  withr::with_dir(dir, {
    load_mtcars_example()
    my_plan$command[my_plan$target == "report"] <-
      "saveRDS(coef_regression2_large, file = file_out(\"coef.rds\"))"
    options(clustermq.scheduler = "multicore")
    config <- drake_config(my_plan)
    config$hasty_build <- function(target, config) {
      file.create(target)
    }
    for (jobs in 1:2) {
      if (jobs > 1) {
        skip_on_os("windows")
        skip_if_not_installed("clustermq")
        if ("package:clustermq" %in% search()) {
          detach("package:clustermq", unload = TRUE) # nolint
        }
      }
      config$jobs <- jobs
      expect_warning(
        hasty_make(config = config),
        regexp = "USE AT YOUR OWN RISK"
      )
      expect_true(file.exists("small"))
      unlink("small")
      expect_false(file.exists("small"))
      expect_equal(length(intersect(my_plan$target, cached())), 0)
      expect_false(file.exists("coef.rds"))
    }
    if ("package:clustermq" %in% search()) {
      detach("package:clustermq", unload = TRUE) # nolint
    }
  })
})

test_that("remote_hasty_build()", {
  dir <- tempfile()
  dir.create(dir)
  withr::with_dir(dir, {
    load_mtcars_example()
    config <- drake_config(my_plan)
    config <- prepare_config(config)
    config$hasty_build <- hasty_build_default
    o <- remote_hasty_build(
      target = "small",
      deps = list(simulate = simulate),
      config = config
    )
    expect_true(is.data.frame(o$value))
  })
})

test_that("With a minimal config object", {
  dir <- tempfile()
  dir.create(dir)
  withr::with_dir(dir, {
    load_mtcars_example()
    my_plan$command[my_plan$target == "report"][[1]] <-
      quote(saveRDS(coef_regression2_large, file = file_out("coef.rds")))
    options(clustermq.scheduler = "multicore")
    for (jobs in 1:3) {
      x <- drake_config(my_plan)
      config <- list(
        plan = x$plan,
        schedule = x$schedule,
        envir = x$envir,
        jobs = jobs
      )
      if (jobs > 1) {
        skip_on_os("windows")
        skip_if_not_installed("clustermq")
        if ("package:clustermq" %in% search()) {
          detach("package:clustermq", unload = TRUE) # nolint
        }
      }
      if (config$jobs > 2) {
        config$jobs <- NULL
      }
      expect_false(file.exists("coef.rds"))
      expect_warning(
        hasty_make(config = config),
        regexp = "USE AT YOUR OWN RISK"
      )
      expect_true(file.exists("coef.rds"))
      expect_equal(length(intersect(my_plan$target, cached())), 0)
      unlink("coef.rds")
      expect_false(file.exists("coef.rds"))
    }
    if ("package:clustermq" %in% search()) {
      detach("package:clustermq", unload = TRUE) # nolint
    }
  })
})

test_with_dir("required args to hasty_make()", {
  config <- list()
  for (x in c("plan", "schedule", "envir")) {
    suppressWarnings(expect_error(hasty_make(config), regexp = x))
    config[[x]] <- 1
  }
})

test_with_dir("character commands", {
  plan <- data.frame(target = "x", command = "1", stringsAsFactors = FALSE)
  config <- drake_config(plan)
  config$plan <- plan
  expect_warning(hasty_make(config), regexp = "RISK")
})
