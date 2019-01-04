
[![Travis build status](https://travis-ci.org/wlandau/drake.hasty.svg?branch=master)](https://travis-ci.org/wlandau/drake.hasty)

<!-- README.md is generated from README.Rmd. Please edit that file -->
Hasty mode for the drake R package
==================================

Hasty mode is [`clustermq`](https://github.com/mschubert/clustermq) parallelism with all of `drake`'s storage and reproducibility guarantees stripped away.

Install
-------

``` r
library(remotes)
install_github("wlandau/drake.hasty")
```

Use
---

``` r
library(drake.hasty)
load_mtcars_example()
make(my_plan, parallelism = backend_hasty, jobs = 2)
```

Drawbacks
---------

-   **DRAKE NO LONGER PROVIDES EVIDENCE THAT YOUR WORKFLOW IS TRUSTWORTHY OR REPRODUCIBLE. [THE CORE SCIENTIFIC CLAIMS](https://github.com/ropensci/drake#reproducibility-with-confidence) ARE NO LONGER VALID.**
-   There is no cache. You need to write code to store your own targets. The `hasty_build` argument to `make()` and the `default_hasty_build()` function may help you get started.

Advantages
----------

-   There is no overhead from storing and checking targets, so hasty mode runs much faster than `drake`'s standard modes.
-   `drake` still builds the correct targets in the correct order, waiting for dependencies to finish before advancing downstream.
