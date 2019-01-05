context("backend")

test_that("default build function", {
  dir <- tempfile()
  dir.create(dir)
  withr::with_dir(dir, {
    load_mtcars_example()
    my_plan$command[my_plan$target == "report"] <-
      "utils::write.csv(coef_regression2_large, file = file_out(\"coef.csv\"))"
    options(clustermq.scheduler = "multicore")
    config <- drake_config(my_plan, parallelism = backend_hasty)
    for (jobs in 1:2) {
      if (jobs > 1) {
        skip_on_os("windows")
        skip_if_not_installed("clustermq")
        if ("package:clustermq" %in% search()) {
          detach("package:clustermq", unload = TRUE) # nolint
        }
      }
      config$jobs <- jobs
      expect_false(file.exists("coef.csv"))
      expect_warning(make(config = config), regexp = "USE AT YOUR OWN RISK")
      expect_true(file.exists("coef.csv"))
      expect_equal(length(intersect(my_plan$target, cached())), 0)
      unlink("coef.csv")
      expect_false(file.exists("coef.csv"))
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
    my_plan$command[my_plan$target == "report"] <-
      "utils::write.csv(coef_regression2_large, file = file_out(\"coef.csv\"))"
    options(clustermq.scheduler = "multicore")
    for (jobs in 1:2) {
      config <- drake_config(my_plan, parallelism = backend_hasty)
      config$hasty_build <- hasty_build_store
      if (jobs > 1) {
        skip_on_os("windows")
        skip_if_not_installed("clustermq")
        if ("package:clustermq" %in% search()) {
          detach("package:clustermq", unload = TRUE) # nolint
        }
      }
      config$jobs <- jobs
      expect_warning(make(config = config), regexp = "USE AT YOUR OWN RISK")
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
      "utils::write.csv(coef_regression2_large, file = file_out(\"coef.csv\"))"
    options(clustermq.scheduler = "multicore")
    config <- drake_config(my_plan, parallelism = backend_hasty)
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
        make(config = config),
        regexp = "USE AT YOUR OWN RISK"
      )
      expect_true(file.exists("small"))
      unlink("small")
      expect_false(file.exists("small"))
      expect_equal(length(intersect(my_plan$target, cached())), 0)
      expect_false(file.exists("coef.csv"))
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
    config <- drake_config(my_plan, parallelism = backend_hasty)
    config$hasty_build <- hasty_build_default
    o <- remote_hasty_build(
      target = "small",
      deps = list(simulate = simulate),
      config = config
    )
    expect_true(is.data.frame(o$value))
  })
})
