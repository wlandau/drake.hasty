
[![stability-experimental](https://img.shields.io/badge/stability-experimental-orange.svg)](https://github.com/emersion/stability-badges#experimental) [![Travis build status](https://travis-ci.org/wlandau/drake.hasty.svg?branch=master)](https://travis-ci.org/wlandau/drake.hasty) [![Test coverage](https://codecov.io/github/wlandau/drake.hasty/coverage.svg?branch=master)](https://codecov.io/github/wlandau/drake.hasty?branch=master)

<!-- README.md is generated from README.Rmd. Please edit that file -->
Hasty mode for the drake R package
==================================

Hasty mode is accelerated execution with all of `drake`'s storage and reproducibility guarantees stripped away. For experimentation only. Use at your own risk.

Drawbacks
---------

1.  **DRAKE NO LONGER PROVIDES EVIDENCE THAT YOUR WORKFLOW IS TRUSTWORTHY OR REPRODUCIBLE. [THE CORE SCIENTIFIC CLAIMS](https://github.com/ropensci/drake#reproducibility-with-confidence) ARE NO LONGER VALID.**
2.  By default, the cache is not used, so
    1.  You need to write code to store your own targets (in your targets' commands or `config$hasty_build()`), and
    2.  `knitr`/`rmarkdown` reports with calls to `loadd()`/`readd()` will no longer work properly as pieces of the pipeline.

Advantages
----------

1.  Hasty mode is a sandbox. By supplying a `hasty_build` function to your `drake_config()` object, you can experiment with different ways to process targets.
2.  There is no overhead from storing and checking targets, so hasty mode runs much faster than `drake`'s standard modes.
3.  You still have scheduling and dependency management. `drake` still builds the correct targets in the correct order, waiting for dependencies to finish before advancing downstream.

Installation
------------

``` r
library(remotes)
install_github("ropensci/drake")
install_github("wlandau/drake.hasty")
```

Basic usage
-----------

We begin with a `drake` project.

``` r
library(drake.hasty)
plan <- drake_plan(x = rnorm(100), y = mean(x), z = median(x))

plan
#> # A tibble: 3 x 2
#>   target command   
#>   <chr>  <chr>     
#> 1 x      rnorm(100)
#> 2 y      mean(x)   
#> 3 z      median(x)
```

First, create a `drake_config()` object from your workflow.

``` r
config <- drake_config(plan)
```

You really only need the `plan`, `schedule`, and `envir` slots of `config`. Feel free to create them yourself.

``` r
config <- list(
  plan = config$plan,
  schedule = config$schedule,
  envir = config$envir
)
```

Then run the project.

``` r
hasty_make(config = config)
#> Warning: Hasty mode THROWS AWAY REPRODUCIBILITY to gain speed.
#> drake's scientific claims at
#>   https://ropensci.github.io/drake/#reproducibility-with-confidence
#>   are NOT VALID IN HASTY MODE!
#> Targets could be out of date even after make(),
#>   and you have no way of knowing.
#> USE AT YOUR OWN RISK!
#> Details: https://github.com/wlandau/drake.hasty/blob/master/README.md
#> target x
#> target y
#> target z
```

By default, there is no caching or checking in hasty mode, so your targets are never up to date.

``` r
hasty_make(config = config)
#> Warning: Hasty mode THROWS AWAY REPRODUCIBILITY to gain speed.
#> drake's scientific claims at
#>   https://ropensci.github.io/drake/#reproducibility-with-confidence
#>   are NOT VALID IN HASTY MODE!
#> Targets could be out of date even after make(),
#>   and you have no way of knowing.
#> USE AT YOUR OWN RISK!
#> Details: https://github.com/wlandau/drake.hasty/blob/master/README.md
#> target x
#> target y
#> target z
```

Parallel and distributed computing
----------------------------------

If you have the [`clustermq`](https://github.com/mschubert/clustermq) package installed, you can use parallel and distributed computing.

``` r
# Use 2 persistent workers.
config$jobs <- 2

# See https://github.com/mschubert/clustermq for more options.
options(clustermq.scheduler = "multicore")

hasty_make(config = config)
#> Warning: Hasty mode THROWS AWAY REPRODUCIBILITY to gain speed.
#> drake's scientific claims at
#>   https://ropensci.github.io/drake/#reproducibility-with-confidence
#>   are NOT VALID IN HASTY MODE!
#> Targets could be out of date even after make(),
#>   and you have no way of knowing.
#> USE AT YOUR OWN RISK!
#> Details: https://github.com/wlandau/drake.hasty/blob/master/README.md
#> Submitting 2 worker jobs (ID: 6745) ...
#> target x
#> target y
#> target z
#> Master: [0.1s 44.2% CPU]; Worker: [avg 9.9% CPU, max 278.0 Mb]
```

Custom build functions
----------------------

You can customize how each target gets built. By default, `hasty_build_default()` is used.

``` r
hasty_build_default
#> function (target, config) 
#> {
#>     eval(expr = config$commands[[target]], envir = config$eval)
#> }
#> <bytecode: 0x55e852c9c2a8>
#> <environment: namespace:drake.hasty>
```

But there is another built-in function that also stores the targets to `drake`'s cache.

``` r
hasty_build_store
#> function (target, config) 
#> {
#>     value <- eval(expr = config$commands[[target]], envir = config$eval)
#>     config$cache$set(key = target, value = value)
#>     value
#> }
#> <bytecode: 0x55e853913480>
#> <environment: namespace:drake.hasty>
```

To use it, simply add the build function and a [`storr`](https://github.com/richfitz/storr) cache to `config` and run `hasty_make()`.

``` r
config$hasty_build <- hasty_build_store
config$cache <- storr::storr_rds(tempfile())
hasty_make(config = config)
#> Warning: Hasty mode THROWS AWAY REPRODUCIBILITY to gain speed.
#> drake's scientific claims at
#>   https://ropensci.github.io/drake/#reproducibility-with-confidence
#>   are NOT VALID IN HASTY MODE!
#> Targets could be out of date even after make(),
#>   and you have no way of knowing.
#> USE AT YOUR OWN RISK!
#> Details: https://github.com/wlandau/drake.hasty/blob/master/README.md
#> Submitting 2 worker jobs (ID: 6250) ...
#> target x
#> target y
#> target z
#> Master: [0.2s 14.1% CPU]; Worker: [avg 7.6% CPU, max 282.3 Mb]
```

Now you can read targets from the cache.

``` r
readd(z, cache = config$cache)
#> [1] -0.2252586
```

Similarly, you can write your own custom build functions for `config$hasty_build`.
