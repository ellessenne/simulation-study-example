### With this script, we see how to analyse the simulation study run (and exported)
### using the script '01-Code.R'.
### Details on the study are included in the README file of this repository.

### 1- We start by importing the dataset with the results of our study:
dt <- readRDS(file = "data/res.RDS")

### 2- Let's inspect our dataset:
# We can use the head() function
head(dt)
# We can use the RStudio viewer
View(dt)
# We can use any other tool you might like/know
str(dt)
dplyr::glimpse(dt)
# ... etc.
# It's important to note the format of our dataset:
head(dt)
# In this case, it's in long format (one observation per row), but it might be in
# wide format too (depending on how you structured your data)
# Either way, you can use any tool to reshape the data any way you want:
# pivot_*() functions from {tidyr}, melt() and dcast() from {reshape2}, etc.
# I personally like to work in long (tidy) format, as it makes it easy
# to interact with tools such as ggplot2. Die hard Stata users might disagree...

### 3- We could then plot some variables, e.g. for a given method or DGM:
# With a histogram:
hist(subset(dt, dgm == "DGM=1" & model == "Model=1")$estimate, main = "DGM=1 & Model=1")
# With a scatterplot e.g. to compare methods for a given DGM
plot(
  x = subset(dt, dgm == "DGM=1" & model == "Model=1")$estimate,
  y = subset(dt, dgm == "DGM=1" & model == "Model=2")$estimate,
  xlab = "DGM=1 & Model=1",
  ylab = "DGM=1 & Model=2"
)
# We do this to:
# - Check potential outliers
# - Check the potential correlation between methods
# - Get a 'grasp' of our data
# ...and of course, we could do the same using ggplot2 (or lattice)
library(ggplot2)
ggplot(dt, aes(x = estimate, y = std.error)) +
  geom_point() +
  facet_grid(dgm ~ model)
ggplot(dt, aes(x = estimate)) +
  geom_density() +
  facet_wrap(~ model + dgm, labeller = label_both)
# ...and so on

### 4- Now, we could calculate some summary statistics for our observed data,
###    e.g. using group_by from {dplyr} (but {data.table}'s verbs work too, or
###    even base R). I am just using this for illustration purposes, you can use
###    whatever tool you know best!
library(tidyverse)
group_by(dt, dgm, model) %>%
  summarise(
    mean_estimate = mean(estimate),
    sd_estimate = sd(estimate),
    mean_std.error = mean(std.error),
    sd_std.error = sd(std.error)
  )
# Here we can see mean and SDs of point estimates and standard errors
# We can also e.g. calculate bias:
group_by(dt, dgm, model) %>%
  summarise(
    bias = mean(estimate - 0)
  ) # 0 is the true value here!

### 5- All of the above (and much more) can be automated and
###    streamlined by using the {rsimsum} package
library(rsimsum)
# First, we need to define our simulation study:
study <- simsum(
  data = dt,
  estvarname = "estimate",
  se = "std.error",
  true = 0,
  methodvar = "model",
  by = "dgm",
  x = TRUE
)
study
# Then, we can summary our study to get all performance measures:
summary(study)
# ...or just a subset of them
summary(study, stats = c("bias", "power"))
