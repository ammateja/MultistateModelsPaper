
<!-- README.md is generated from README.Rmd. Please edit that file -->

# MultistateModelsPaper

<!-- badges: start -->
<!-- badges: end -->

MultistateModelsPaper provides a package for simulating and fitting
multistate models especially semi-Markov models, to panel data and
interval censored data. This is a wrapper to the Julia package
MultistateModels.jl. This version of the package is a stable version
used to accompany the paper “Assessing treatment efficacy for interval
censored endpoints using multistate semi-Markov models fit to multiple
data streams”.

## Installation

You can install MultistateModelsPaper from [GitHub](https://github.com/)
with:

``` r
# install.packages("devtools")
devtools::install_github("ammateja/multistatemodels_paper")
```

``` r
library(MultistateModelsPaper)
```

The vignette `illness-death` shows how to fit a basic 3-state
illness-death model. In this simple setting, patients are healthy at the
start of follow- up. The model has three states – healthy, ill, and dead
– and three transitions — healthy to ill, healthy to dead, and ill to
dead. Disease recurrence is interval censored but the time of death is
exactly observed.
