% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions.R
\name{set_parameters}
\alias{set_parameters}
\title{Set parameters}
\usage{
set_parameters(model, newvalues)
}
\arguments{
\item{model}{multistate model}

\item{newvalues}{A list, each element of the list is new parameters for each hazard}
}
\description{
Set model parameters given a vector of values.
Copies newvalues to model.parameters.
}
\examples{
h12 <- Hazard(formula = 0~1, statefrom = 1, stateto=2, family="wei")
h13 <- Hazard(formula = 0~1, statefrom = 1, stateto=3, family="wei")
h23 <- Hazard(formula = 0~1, statefrom = 2, stateto=3, family="wei")
model_fit <- multistatemodel(hazard = c(h12, h13, h23), data=illness_death_dat)
model_fit <- set_parameters(model = model_fit, newvalues = list(h12 = c(log(1.25), log(1.5)),
h13 = c(log(1.25), log(1)), h23 = c(log(1.25), log(2))))
\dontshow{
JuliaConnectoR::stopJulia()
}
}
