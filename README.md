
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

First, create a `drake_config()` object from your workflow. Supply the `backend_hasty()` function to the `parallelism` argument.

``` r
config <- drake_config(plan, parallelism = backend_hasty)
```

Then run the project.

``` r
make(config = config)
#> Warning: `drake` can indeed accept a custom scheduler function for the
#> `parallelism` argument of `make()` but this is only for the sake of
#> experimentation and graceful deprecation. Your own custom schedulers may
#> cause surprising errors. Use at your own risk.
#> Warning: Hasty mode THROWS AWAY REPRODUCIBILITY to gain speed.
#> drake's scientific claims at
#>   https://ropensci.github.io/drake/#reproducibility-with-confidence
#>   are NOT VALID IN HASTY MODE!
#> Targets could be out of date even after make(),
#>   and you have no way of knowing.
#> USE AT YOUR OWN RISK!
#> Details: https://ropenscilabs.github.io/drake-manual/hpc.html#hasty-mode
#> target x
#> target y
#> target z
```

By default, there is no caching or checking in hasty mode, so your targets are never up to date.

``` r
make(config = config)
#> Warning: `drake` can indeed accept a custom scheduler function for the
#> `parallelism` argument of `make()` but this is only for the sake of
#> experimentation and graceful deprecation. Your own custom schedulers may
#> cause surprising errors. Use at your own risk.
#> Warning: Hasty mode THROWS AWAY REPRODUCIBILITY to gain speed.
#> drake's scientific claims at
#>   https://ropensci.github.io/drake/#reproducibility-with-confidence
#>   are NOT VALID IN HASTY MODE!
#> Targets could be out of date even after make(),
#>   and you have no way of knowing.
#> USE AT YOUR OWN RISK!
#> Details: https://ropenscilabs.github.io/drake-manual/hpc.html#hasty-mode
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

make(config = config)
#> Warning: `drake` can indeed accept a custom scheduler function for the
#> `parallelism` argument of `make()` but this is only for the sake of
#> experimentation and graceful deprecation. Your own custom schedulers may
#> cause surprising errors. Use at your own risk.
#> Warning: Hasty mode THROWS AWAY REPRODUCIBILITY to gain speed.
#> drake's scientific claims at
#>   https://ropensci.github.io/drake/#reproducibility-with-confidence
#>   are NOT VALID IN HASTY MODE!
#> Targets could be out of date even after make(),
#>   and you have no way of knowing.
#> USE AT YOUR OWN RISK!
#> Details: https://ropenscilabs.github.io/drake-manual/hpc.html#hasty-mode
#> Submitting 2 worker jobs (ID: 6637) ...
#> target x
#> target y
#> target z
#> Master: [0.1s 33.7% CPU]; Worker: [avg 17.0% CPU, max 284.2 Mb]
```

Custom build functions
----------------------

You can customize how each target gets built. By default, `hasty_build_default()` is used.

``` r
hasty_build_default
#> function (target, config) 
#> {
#>     tidy_expr <- eval(expr = config$layout[[target]]$command_build, 
#>         envir = config$eval)
#>     eval(expr = tidy_expr, envir = config$eval)
#> }
#> <bytecode: 0x560110e621c0>
#> <environment: namespace:drake.hasty>
```

But there is another built-in function that also stores the targets to `drake`'s cache.

``` r
hasty_build_store
#> function (target, config) 
#> {
#>     tidy_expr <- eval(expr = config$layout[[target]]$command_build, 
#>         envir = config$eval)
#>     value <- eval(expr = tidy_expr, envir = config$eval)
#>     config$cache$set(key = target, value = value)
#>     value
#> }
#> <bytecode: 0x56010fd80608>
#> <environment: namespace:drake.hasty>
```

To use it, simply add it to the `config` object and run `make()`.

``` r
config$hasty_build <- hasty_build_store
make(config = config)
#> Warning: `drake` can indeed accept a custom scheduler function for the
#> `parallelism` argument of `make()` but this is only for the sake of
#> experimentation and graceful deprecation. Your own custom schedulers may
#> cause surprising errors. Use at your own risk.
#> Warning: Hasty mode THROWS AWAY REPRODUCIBILITY to gain speed.
#> drake's scientific claims at
#>   https://ropensci.github.io/drake/#reproducibility-with-confidence
#>   are NOT VALID IN HASTY MODE!
#> Targets could be out of date even after make(),
#>   and you have no way of knowing.
#> USE AT YOUR OWN RISK!
#> Details: https://ropenscilabs.github.io/drake-manual/hpc.html#hasty-mode
#> Submitting 2 worker jobs (ID: 6165) ...
#> target x
#> target y
#> target z
#> Master: [0.2s 11.4% CPU]; Worker: [avg 9.3% CPU, max 284.2 Mb]
```

Now you can read targets from the cache.

``` r
readd(z)
#> [1] 0.1276097
```

Similarly, you can write your own custom build functions for `config$hasty_build`.
