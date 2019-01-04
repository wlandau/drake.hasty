context("hasty")

drake::test_with_dir("hasty parallelism", {
  skip_on_cran()
  load_mtcars_example()
  my_plan$command[my_plan$target == "report"] <-
    "utils::write.csv(coef_regression2_large, file = file_out(\"coef.csv\"))"
  options(clustermq.scheduler = "multicore")
  for (jobs in 1:2) {
    if (jobs > 1) {
      skip_on_os("windows")
      skip_if_not_installed("clustermq")
      if ("package:clustermq" %in% search()) {
        detach("package:clustermq", unload = TRUE) # nolint
      }
    }
    # default build function
    expect_false(file.exists("coef.csv"))
    expect_warning(
      make(my_plan, envir = e, parallelism = "hasty", jobs = jobs),
      regexp = "USE AT YOUR OWN RISK"
    )
    expect_true(file.exists("coef.csv"))
    expect_equal(length(intersect(my_plan$target, cached())), 0)
    unlink("coef.csv")
    expect_false(file.exists("coef.csv"))
    # custom build function
    expect_false(file.exists("small"))
    hasty_write <- function(target, config) {
      file.create(target)
    }
    expect_warning(
      make(
        my_plan,
        envir = e,
        parallelism = "hasty",
        hasty_build = hasty_write
      ),
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