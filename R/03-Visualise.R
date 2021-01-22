### With this script, we see how to visualise results from the simulation study
### run (and exported) using the script '01-Code.R' and analysed with '02-Analyse.R'.
### Details on the study are included in the README file of this repository.

### 1- We start by importing the dataset with the results of our study:
dt <- readRDS(file = "data/res.RDS")

### 2- Then, we summarise the study once again using {rsimsum}:
library(rsimsum)
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

### 3- Now, we can obtain a variety of plots too using the autoplot() function
# Plots for the point estimates:
library(ggplot2)
autoplot(study, type = "est")
autoplot(study, type = "est_ba")
autoplot(study, type = "est_ridge")
autoplot(study, type = "est_hex")
autoplot(study, type = "est_density")
# (with analogous for the standard errors), e.g.
autoplot(study, type = "se_ba")
# Zip plots for coverage probabilities
autoplot(study, type = "zip")
# Plots for the performance measures
autoplot(summary(study), type = "forest", stats = "bias")
autoplot(summary(study), type = "lolly", stats = "bias")
autoplot(summary(study), type = "heat", stats = "bias")
# And this can be obtained with any summary statistic of interest
# Plots are also standard gg* objects, so they can be further customised at will:
autoplot(study, type = "est_ridge") +
  theme_bw(base_family = "JetBrains Mono") +
  viridis::scale_colour_viridis(discrete = TRUE) +
  viridis::scale_fill_viridis(discrete = TRUE) +
  labs(x = "Point estimate", color = "", fill = "", title = "Here's a customised plot!")
# {rsimsum} can do a lot more, if you're interested check the
# webpage of the package: https://ellessenne.github.io/rsimsum/

### 4- To create some tables, {rsimsum} supports the kable() function
###    to output to a variety of formats:
# Markdown:
kable(study)
# LaTeX:
kable(study, format = "latex")
# Markdown, for a subset of performance measures:
kable(study, stats = c("bias", "power"))

### 5- Lots of customisation can be achieved by extracting data from the `study`
###    object and creating tables/plots by hand:
study_results <- get_data(study, stats = c("bias", "power"))
# E.g. a better table:
library(tidyverse)
library(glue)
library(kableExtra)
study_results %>%
  mutate(y = glue("{formattable::comma(est, 4)} ({formattable::comma(mcse, 4)})")) %>%
  select(stat, model, dgm, y) %>%
  pivot_wider(names_from = "model", values_from = "y") %>%
  mutate(stat = tools::toTitleCase(stat)) %>%
  arrange(stat, dgm) %>%
  kable(
    format = "markdown",
    col.names = c("Performance measure", "DGM", "Model = 1", "Model = 2"),
    align = "rcrr"
  )
