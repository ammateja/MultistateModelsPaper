## ----setup, include = FALSE------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  warning=FALSE, 
  message=FALSE,
  comment = "#>"
)
set.seed(1)


## ----class.source='fold-show', eval=F--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#> knitr::purl(input="illness-death.Rmd")




## ----class.source='fold-show'----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#install.packages("JuliaConnectoR")
library(JuliaConnectoR)


## ----class.source='fold-show'----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#install.packages("dplyr")
#install.packages("ggplot2")
#install.packages("knitr")
#install.packages("kableExtra")
library(ggplot2)
library(dplyr)


## ----class.source='fold-show', warning=FALSE, message=F--------------------------------------------------------------------------------------------------------------------------------------------------------
if (JuliaConnectoR::juliaSetupOk()){
    JuliaConnectoR::juliaEval('
       import Pkg
       Pkg.add(url = "https://github.com/fintzij/MultistateModels.jl.git")
       Pkg.add("CSV")
       Pkg.add("DataFrames")
       Pkg.add("Random")')
  } else {
    stop("Julia setup incorrect.
         Ensure Julia version >= 1.10 is properly installed.")
  }


## ----class.source='fold-show', warning=FALSE, message=FALSE----------------------------------------------------------------------------------------------------------------------------------------------------
#install.packages("devtools")
devtools::install_github("ammateja/MultistateModelsPaper", quiet=TRUE)
library(MultistateModelsPaper)




## --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Function to make parameters
makepars <- function() {
  parameters <- list(h12 = c(log(1.25), log(1.5)), 
                     h13 = c(log(1.25), log(1)), 
                     h23 = c(log(1.25), log(2)))
  return(parameters)
}


## --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Function to make the assessment times
make_obstimes <- function(ntimes) {
  #observation times
  interval <- seq(0, 1, length.out = ntimes+1)
  # random visit times drawn from a beta(1.5, 1.5)
  #distribution centered around the scheduled time and scaled to span the midpoints between scheduled assessments
  times <- interval[-c(1, length(interval))] + (rbeta(length(interval[-c(1, length(interval))]), 1.5, 1.5) - 0.5)*diff(interval)[1]
  #time of enrollment and end of follow-up were 0 and 1 year for all
  times <- c(0, times, 1)

  return(times)
}


## --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Initialize empty data frame and loop through each subject
set.seed(1)
data <- NULL
for (i in 1:250) {
  #create observation times
  visitdays <- make_obstimes(12)
  #set id
  id <- rep(i, 12)
  #Reformat dataset so each row has tstart and tstop
  tstart <- visitdays[-length(visitdays)]
  tstop <- visitdays[-1]
  #set statefrom and stateto to both be 1
  statefrom <- rep(1, 12)
  stateto <- rep(1, 12)
  #set obstype equal to 2
  obstype <- rep(2, 12)
  d <- data.frame(id=id, tstart=tstart, tstop=tstop, statefrom=statefrom, stateto=stateto, obstype=obstype)
  data <- rbind(data, d)
}


## --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#set all hazards to be Weibull
h12 <- MultistateModelsPaper::Hazard(formula = 0~1, statefrom = 1, stateto=2, family="wei")
h13 <- MultistateModelsPaper::Hazard(formula = 0~1, statefrom = 1, stateto=3, family="wei")
h23 <- MultistateModelsPaper::Hazard(formula = 0~1, statefrom = 2, stateto=3, family="wei")

#Initalize model
model <- MultistateModelsPaper::multistatemodel(hazard = c(h12, h13, h23), data=data)
#Starting parameters
parameters <- makepars()
#Set parameters
model_sim <- MultistateModelsPaper::set_parameters(model=model, newvalues=parameters)


## --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
JuliaConnectoR::juliaEval("using Random")
JuliaConnectoR::juliaEval("Random.seed!(0)")
#Simulate one sample path per subject
paths <- MultistateModelsPaper::simulate(model=model_sim, nsim=1, paths=TRUE, data=FALSE)


## --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
observe_subjdat <- function(path, model) {
  
  #Get data used in model and loop through each subject
  d <- as.data.frame(model$data)
  subjdat <- NULL
  
  for (i in 1:length(path)) {
    
    #Get observed visit times for one subject
    subj.dat.raw <- d[d$id == i, ]
    #Combine observed visit times with times from simulated sample paths --> sort and ensure all times are unique
    obstimes <- unique(sort(c(0, subj.dat.raw$tstop, path[[i]]$times[path[[i]]$states ==3])))
    
    #If there is a transition from state 2 to state 3, add ghost transition with time epsilon. Again ensure times are sorted
    if (sum(c(2,3) %in% path[[i]]$states) == 2) {
      
      new <- path[[i]]$times[length(path[[i]]$times)] - sqrt(.Machine$double.eps)
      obstimes <- sort(c(obstimes, new))
      
    }
    
    #Cull times greater than max time from simulated path
    obsinds <- unlist(lapply(obstimes, function(x){max(which(path[[i]]$times <= x))}))
    #Determine state at each observation time
    obsstates <- path[[i]]$states[obsinds]
    
    #Create dataset for one subject
    data <- data.frame(id = rep(path[[i]]$subj, (length(obstimes)-1)), 
                      tstart = obstimes[-length(obstimes)], 
                      tstop = obstimes[-1], 
                      statefrom = obsstates[-length(obsstates)], 
                      stateto = obsstates[-1])
    #Remove any data after death
    data <- data[data$stateto != 3 | data$statefrom != 3, ]
    #Set obstype to 2 unless death, then it is directly observed
    data$obstype <- ifelse(data$stateto == 3, 1, 2)
    data$obstype <- ifelse(data$statefrom == data$stateto, 1, data$obstype)
    
    subjdat <- rbind(subjdat, data)
    
  }
  
  subjdat <- subjdat %>% dplyr::arrange(id, tstart)
  
  return(subjdat)
  
}


## --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
dat <- observe_subjdat(paths, model_sim)






## --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Obtain knots for each transition
#median observed transition time for each possible event
knots12 <- c(0, quantile(JuliaConnectoR::juliaLet("MultistateModels.extract_sojourns(1, 2, MultistateModels.extract_paths(dat))", dat=JuliaConnectoR::juliaCall("DataFrame", dat)), c(0.5, 1)))
knots13 <- c(0, quantile(JuliaConnectoR::juliaLet("MultistateModels.extract_sojourns(1, 3, MultistateModels.extract_paths(dat))", dat=JuliaConnectoR::juliaCall("DataFrame", dat)), c(0.5, 1)))
knots23 <- c(0, quantile(JuliaConnectoR::juliaLet("MultistateModels.extract_sojourns(2, 3, MultistateModels.extract_paths(dat))", dat=JuliaConnectoR::juliaCall("DataFrame", dat)), c(0.5, 1)))

#Set transition intensity for each transition to be a degree 1 spline, interior knot at median, and boundary knots at 0 and max    
h12_sp <- MultistateModelsPaper::Hazard(formula = 0~1, statefrom = 1, stateto=2, family="sp", degree=1, knots = knots12[-c(1, length(knots12))], boundaryknots = knots12[c(1, length(knots12))], extrapolation = "flat")
h13_sp <- MultistateModelsPaper::Hazard(formula = 0~1, statefrom = 1, stateto=3, family="sp", degree=1, knots = knots13[-c(1, length(knots13))], boundaryknots = knots13[c(1, length(knots13))], extrapolation = "flat")
h23_sp <- MultistateModelsPaper::Hazard(formula = 0~1, statefrom = 2, stateto=3, family="sp", degree=1, knots = knots23[-c(1, length(knots23))], boundaryknots = knots23[c(1, length(knots23))], extrapolation = "flat")

#Set up model
model_fit <- MultistateModelsPaper::multistatemodel(hazard = c(h12_sp, h13_sp, h23_sp), data=dat)
#initialize parameters to set the starting values of the transition intensities to MLEs of the Markov model
model_fit <- MultistateModelsPaper::initialize_parameters(model = model_fit)
#Fi the model
model_fitted <- MultistateModelsPaper::fit(model = model_fit, verbose=TRUE, compute_vcov = TRUE, ess_target_initial = 50, ascent_threshold = 0.2, stopping_threshold = 0.2, tol = 0.001)


## --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
JuliaConnectoR::juliaEval("Random.seed!(0)")
#Set up model for simulation with data from fitted model
model_sim2 <- MultistateModelsPaper::multistatemodel(hazard = c(h12_sp, h13_sp, h23_sp), data=as.data.frame(model_sim$data))

#Set parameters to MLEs of fitted model
model_sim2 <- MultistateModelsPaper::set_parameters(model = model_sim2, newvalues = list(JuliaConnectoR::juliaGet(model_fitted$parameters[1])$data, JuliaConnectoR::juliaGet(model_fitted$parameters[2])$data, JuliaConnectoR::juliaGet(model_fitted$parameters[3])$data))

#Simulate 20 paths per subject
paths_sim <- MultistateModelsPaper::simulate(model = model_sim2, nsim = 20, paths = TRUE, data = FALSE)


## ----echo=F----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
times <- seq(0, 1, 0.05)
times_new <- seq(0, 1, 0.01)

intervals <- dplyr::bind_rows(lapply(paths, function(x){as.data.frame(cbind(times, rep(x$subj, length(times)), findInterval(times, x$times), x$states[findInterval(times, x$times)]))}))

times_summary <- intervals %>% dplyr::group_by(times, V4) %>% dplyr::summarize(n=n(), per=100*(n/length(paths)), .groups="drop")

intervals_mod <- dplyr::bind_rows(lapply(paths_sim, function(x){as.data.frame(cbind(times_new, rep(x$subj, length(times_new)), findInterval(times_new, x$times), x$states[findInterval(times_new, x$times)]))}))

times_summary_mod <- intervals_mod %>% dplyr::group_by(times_new, factor(V4), .drop=FALSE) %>% dplyr::summarize(n=n(), per=100*(n/length(paths_sim)), .groups="drop")


## ----echo=F----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
inc2 <- rep(1, length(paths))
inc3 <- rep(1, length(paths))

for (i in 1:length(paths)) {
  
  if (paths[[i]]$states[2] == 2) {
    inc2[i] <- paths[[i]]$times[2]
  } 
  
  if (3 %in% paths[[i]]$states) {
    inc3[i] <- max(paths[[i]]$times)
  }
  
}

times2 <- rep(0, length(times))

for (i in 1:length(times)) {
  times2[i] <- 100*mean(inc2 < times[i])
}

times3 <- rep(0, length(times))

for (i in 1:length(times)) {
  times3[i] <- 100*mean(inc3 < times[i])
}

incidence <- data.frame(times = rep(times, 2), incidence = c(times2, times3), state = c(rep(2, length(times)), rep(3, length(times))))


inc2_mod <- rep(1, length(paths_sim))
inc3_mod <- rep(1, length(paths_sim))

for (i in 1:length(paths_sim)) {
  
  if (paths_sim[[i]]$states[2] == 2) {
    inc2_mod[i] <- paths_sim[[i]]$times[2]
  } 
  
  if (3 %in% paths_sim[[i]]$states) {
    inc3_mod[i] <- max(paths_sim[[i]]$times)
  }
  
}

times2_mod <- rep(0, length(times_new))

for (i in 1:length(times_new)) {
  times2_mod[i] <- 100*mean(inc2_mod < times_new[i])
}

times3_mod <- rep(0, length(times_new))

for (i in 1:length(times_new)) {
  times3_mod[i] <- 100*mean(inc3_mod < times_new[i])
}

incidence_mod <- data.frame(times = rep(times_new, 2), incidence = c(times2_mod, times3_mod), state = c(rep(2, length(times_new)), rep(3, length(times_new))))



## ----echo=F----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
asymptotic_bootstrap_incidence <- function(model, pars, vcov, sims_per_subj, nboot) {
  
  npars <- length(pars)
  pardraws <- rep(0, npars)
  
  U <- svd(vcov)$u
  D <- svd(vcov)$d
  
  D[D < 0] <- 0
  
  S <- U%*%diag(sqrt(D))
  
  ests_inc2 <- matrix(0, nrow=length(times_new), ncol=nboot)
  ests_inc3 <- matrix(0, nrow=length(times_new), ncol=nboot)
  
  ests_prev1 <- matrix(0, nrow=length(times_new), ncol=nboot)
  ests_prev2 <- matrix(0, nrow=length(times_new), ncol=nboot)
  ests_prev3 <- matrix(0, nrow=length(times_new), ncol=nboot)
  
  for (k in 1:nboot) {
    
    pardraws[1:npars] <- as.matrix(pars) + S%*%rnorm(npars)
    
    elem_ptr <- JuliaConnectoR::juliaGet(model$parameters)$elem_ptr
    newvalues <- vector("list", length(elem_ptr)-1)
    for (i in 1:(length(elem_ptr)-1)) {
      newvalues[[i]] <- pardraws[elem_ptr[i]:(elem_ptr[i+1]-1)]
    }
    
    model <- MultistateModelsPaper::set_parameters(model=model, newvalues = newvalues)
    paths_sim <- MultistateModelsPaper::simulate(model=model, nsim = sims_per_subj, paths=TRUE, data=FALSE)
    
    inc2_mod <- rep(1, length(paths_sim))
    inc3_mod <- rep(1, length(paths_sim))

    for (i in 1:length(paths_sim)) {
  
      if (paths_sim[[i]]$states[2] == 2) {
        inc2_mod[i] <- paths_sim[[i]]$times[2]
      } 
  
      if (3 %in% paths_sim[[i]]$states) {
        inc3_mod[i] <- max(paths_sim[[i]]$times)
      }
  
    }

    times2_mod <- rep(0, length(times_new))

    for (i in 1:length(times_new)) {
      times2_mod[i] <- 100*mean(inc2_mod < times_new[i])
    }

    times3_mod <- rep(0, length(times_new))

    for (i in 1:length(times_new)) {
      times3_mod[i] <- 100*mean(inc3_mod < times_new[i])
    }

    ests_inc2[ ,k] <- times2_mod
    ests_inc3[ ,k] <- times3_mod
    
    intervals_mod <- bind_rows(lapply(paths_sim, function(x){as.data.frame(cbind(times_new, rep(x$subj, length(times_new)), findInterval(times_new, x$times), x$states[findInterval(times_new, x$times)]))}))

    times_summary_mod <- intervals_mod %>% group_by(times_new, factor(V4), .drop=FALSE) %>% dplyr::summarize(n=n(), per=100*(n/length(paths_sim)), .groups="drop")
    ests_prev1[ ,k] <- as.numeric(times_summary_mod[times_summary_mod$`factor(V4)` ==  1, ]$per)
    ests_prev2[ ,k] <- as.numeric(times_summary_mod[times_summary_mod$`factor(V4)` ==  2, ]$per)
    ests_prev3[ ,k] <- as.numeric(times_summary_mod[times_summary_mod$`factor(V4)` ==  3, ]$per)
    
  }
  

  
  return(list(t(apply(ests_inc2, 1, quantile, na.rm=T, probs = c(0.025))), t(apply(ests_inc2, 1, quantile, na.rm=T, probs = c(0.975))), t(apply(ests_inc3, 1, quantile, na.rm=T, probs = c(0.025))), t(apply(ests_inc3, 1, quantile, na.rm=T, probs = c(0.975))), 
              t(apply(ests_prev1, 1, quantile, na.rm=T, probs = c(0.025))), t(apply(ests_prev1, 1, quantile, na.rm=T, probs = c(0.975))), t(apply(ests_prev2, 1, quantile, na.rm=T, probs = c(0.025))), t(apply(ests_prev2, 1, quantile, na.rm=T, probs = c(0.975))), t(apply(ests_prev3, 1, quantile, na.rm=T, probs = c(0.025))), t(apply(ests_prev3, 1, quantile, na.rm=T, probs = c(0.975)))))
  
  
}


## ----echo=F----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#JuliaConnectoR::juliaEval("Random.seed!(0)")
#set.seed(1)
#inc_cis <- asymptotic_bootstrap_incidence(model_sim2, JuliaConnectoR::juliaGet(model_fitted$parameters)$data, model_fitted$vcov, 20, 1000)

inc_cis <- readRDS("cis.RDS")


## ----fig.height=6, fig.width=8, echo=F-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ggplot() + 
  geom_point(data=times_summary, aes(x=times, y=per, col=factor(V4))) + 
  geom_line(data=times_summary_mod, aes(x=times_new, y=per, col=`factor(V4)`), lwd=1) + 
  geom_ribbon(data = data.frame(x=times_new, y1=as.numeric(inc_cis[[5]]), y2=as.numeric(inc_cis[[6]])), aes(x=x, ymin=y1, ymax=y2), fill="forestgreen", alpha=0.15) +
  geom_ribbon(data = data.frame(x=times_new, y1=as.numeric(inc_cis[[7]]), y2=as.numeric(inc_cis[[8]])), aes(x=x, ymin=y1, ymax=y2), fill="blue", alpha=0.15) +
  geom_ribbon(data = data.frame(x=times_new, y1=as.numeric(inc_cis[[9]]), y2=as.numeric(inc_cis[[10]])), aes(x=x, ymin=y1, ymax=y2), fill="darkred", alpha=0.15) +
  theme_bw() +
  scale_color_manual(values = c("forestgreen", "blue", "darkred"), labels = c("Healthy", "Ill", "Dead")) +
  labs(y = "Prevalence (%)", x = "Time", col = "State") +
  scale_x_continuous(breaks = seq(0, 1, 0.1)) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25))


## ----fig.height=6, fig.width=8, echo=F-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ggplot() + 
  geom_point(data=incidence, aes(x=times, y=incidence, col=factor(state))) + 
  geom_line(data=incidence_mod, aes(x=times, y=incidence, col=factor(state)), lwd=1) +
  geom_ribbon(data = data.frame(x=times_new, y1=as.numeric(inc_cis[[1]]), y2=as.numeric(inc_cis[[2]])), aes(x=x, ymin=y1, ymax=y2), fill="blue", alpha=0.15) +
  geom_ribbon(data = data.frame(x=times_new, y1=as.numeric(inc_cis[[3]]), y2=as.numeric(inc_cis[[4]])), aes(x=x, ymin=y1, ymax=y2), fill="darkred", alpha=0.15) +
  theme_bw() +
  scale_color_manual(values = c("blue", "darkred"), labels = c("Ill", "Dead")) +
  labs(y = "Cumulative Incidence (%)", x = "Time", col = "State") +
  scale_x_continuous(breaks = seq(0, 1, 0.1)) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25))

