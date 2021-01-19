### With this script, we see how to setup and run a simulation study.
### Details on the study are included in the README file of this repository.

### 1- Start small, as a proof-of-concept

# Simulating a confounder
N <- 100
Z <- rnorm(n = N)

# Simulating an exposure
.gamma0 <- 1
.gamma1 <- 3
LP <- .gamma0 + .gamma1 * Z
P_X <- boot::inv.logit(LP) # Check that it is equivalent to: 1 / (1 + exp(-LP))
X <- rbinom(n = N, size = 1, prob = P_X)

# Simulating an outcome
.alpha0 <- 10
.alpha1 <- 5
Y <- rnorm(n = N, mean = .alpha0 + .alpha1 * Z)

# Putting all data together in a dataset
dt <- data.frame(X, Y, Z)

# Fit two models:
# 1. A model that ignores the confounder
m1 <- lm(Y ~ X, data = dt)
# 2. A model that adjust for the confounder
m2 <- lm(Y ~ X + Z, data = dt)

# Then, we compare the treatment effect estimate
summary(m1)
summary(m2)
# As expected, the estimate of X from m1 is biased
# Remember: X and Y are independent, so the treatment effect should be zero!
# This is, in principle, what we should repeat B times in our simulation study

### 2- Now, start generalising the experiment above

# First, we create a function that returns a simulated dataset
make_data <- function(N, i, dgm, .gamma0, .gamma1, .alpha0, .alpha1) {
  # Confounder
  Z <- rnorm(n = N)
  # Exposure
  LP <- .gamma0 + .gamma1 * Z
  P_X <- boot::inv.logit(LP)
  X <- rbinom(n = N, size = 1, prob = P_X)
  # Outcome outcome
  Y <- rnorm(n = N, mean = .alpha0 + .alpha1 * Z)
  # Assemble a data.frame
  dt <- data.frame(X, Y, Z, i, dgm)
  # Return
  return(dt)
}

# Remember to test the function:
dt <- make_data(N = 100, i = 1, dgm = 1, .gamma0 = 1, .gamma1 = 3, .alpha0 = 10, .alpha1 = 5)
head(dt)

# Second, we create a function that fits a 'method'
make_analysis <- function(data, model) {
  # Define which model to fit
  if (model == 1) {
    f <- Y ~ X
  } else if (model == 2) {
    f <- Y ~ X + Z
  }
  # Fit the model
  m <- lm(formula = f, data = data)
  # Now, we return a data.frame with the results
  # Not really necessary, but I find it easier to work with
  # First, tidy the model using broom::tidy (if the analysis method is supported - in this case it is)
  # Install {broom} if not already available on your machine
  require("broom")
  out <- tidy(m)
  # Then, we focus on the coefficient for X only
  out <- subset(
    out,
    term == "X",
    select = c("estimate", "std.error")
  )
  # subset() is not the most efficient, but we try to limit dependencies here
  # Then, add which iteration we are fitting (column `i` in data)
  out[["i"]] <- unique(data[["i"]])
  # Then, add which DGM we are fitting (column `dgm` in data)
  out[["dgm"]] <- unique(data[["dgm"]])
  # Then, add which model we are fitting
  out[["model"]] <- model
  # ...then, return
  return(out)
}

# Remember to test the function:
make_analysis(data = dt, model = 1)
make_analysis(data = dt, model = 2)
# Seems ok!

### 3- We finally have functions to simulate the data according to our DGM and to fit out analysis methods.
###    It's time to run B iterations!

# Again, start with a small B to test
B <- 3

# Here I like using the purrr::map_* family of functions from the {purrr} package,
# as it can easily be generalised to run in parallel via {furrr}.
# Step #1 is to simulate B datasets, e.g. with N = 100 subjects each:
library(purrr)
list_of_dt <- purrr::map(.x = seq(B), .f = make_data, N = 100, dgm = 1, .gamma0 = 1, .gamma1 = 3, .alpha0 = 10, .alpha1 = 5)
# Check that we simulated data correctly:
purrr::map(.x = list_of_dt, .f = head)
# Looks fine!

# Now, same but we fit both analysis methods to each simulated dataset:
res_m1 <- purrr::map_dfr(.x = list_of_dt, .f = make_analysis, model = 1)
res_m2 <- purrr::map_dfr(.x = list_of_dt, .f = make_analysis, model = 2)
# Here I use purrr::map_dfr as it binds the row together in a single data.frame:
res_m1
res_m2
# Then, we bind the two datasets together
res <- rbind(res_m1, res_m2)
res
# Once again, looks fine!

### 4- Now, we actually set-up and run the simulation study we aim to run
###    We have two DGMs:
###     1. Z is a confounder, with .alpha1 = 5
###     2. Z is not a confounder, with .alpha1 = 0
###    (Check the DAGs in the README file)
###    The other parameters of the DGMs are .gamma0 = 1, .gamma1 = 3, .alpha0 = 10, N = 200
###    Also, we run B = 10000 replications

# We simulate data according to our two DGMs
# First, we set a seed for reproducibility
set.seed(43875683)
# Here we need two separate function calls, one per each DGM
B <- 10000
data_dgm1 <- purrr::map(.x = seq(B), .f = make_data, N = 200, dgm = 1, .gamma0 = 1, .gamma1 = 3, .alpha0 = 10, .alpha1 = 5)
data_dgm2 <- purrr::map(.x = seq(B), .f = make_data, N = 200, dgm = 2, .gamma0 = 1, .gamma1 = 3, .alpha0 = 10, .alpha1 = 0)
# And let's combine the lists into a single one for simplicity
list_of_dt <- c(data_dgm1, data_dgm2)

# Then, we fit both analysis methods to each simulated dataset:
res_m1 <- purrr::map_dfr(.x = list_of_dt, .f = make_analysis, model = 1)
res_m2 <- purrr::map_dfr(.x = list_of_dt, .f = make_analysis, model = 2)
res <- rbind(res_m1, res_m2)

### 5- We go get a cup of coffee while it run, and then we're done!

# Actually, before saving our results, we can simplify our life (future us will thank us)
# by creating factors for our DGMs and methods:
res[["dgm"]] <- factor(res[["dgm"]], levels = 1:2, labels = c("DGM=1", "DGM=2"))
res[["model"]] <- factor(res[["model"]], levels = 1:2, labels = c("Model=1", "Model=2"))

# Then, we save the results in RDS format
saveRDS(object = res, file = "data/res.RDS")

### 6- BONUS
###    With long running jobs, we might want to implement a progress bar to
###    keep track of progress.

# Here we create a wrapper around the make_analysis() function to do just that:
make_analysis_progress <- function(i, .progress.bar, ...) {
  out <- make_analysis(data = list_of_dt[[i]], ...)
  setTxtProgressBar(pb = .progress.bar, value = i)
  return(out)
}

# Lets simulate B = 200 data sets for a given DGM to test that:
B <- 200
test_data <- purrr::map(.x = seq(B), .f = make_data, N = 200, dgm = 1, .gamma0 = 1, .gamma1 = 3, .alpha0 = 10, .alpha1 = 5)
# Same as before, nothing new here

# Then, we create a progress bar to pass to our new function:
pb <- txtProgressBar(min = 0, max = B, style = 3) # The best style

# Finally, we run the analysis with the new function:
test_res <- purrr::map_dfr(.x = seq_along(test_data), .f = make_analysis_progress, model = 1, .progress.bar = pb)
# Same for the other method, omitted here but it's trivial to generalise.
# Compare carefully this call to purrr::map_dfr vs the previous call!
