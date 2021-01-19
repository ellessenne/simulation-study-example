# Confounding
N <- 1e6

# Confounder
Z <- rnorm(n = N)

# Exposure
.gamma0 <- 1
.gamma1 <- 3
LP <- .gamma0 + .gamma1 * Z
P_X <- boot::inv.logit(LP)
P_X_test <- 1 / (1 + exp(-LP))

X <- rbinom(n = N, size = 1, prob = P_X)

# Outcome
.alpha0 <- 10
.alpha1 <- 5
Y <- rnorm(n = N, mean = .alpha0 + .alpha1 * Z)

# Data
dt <- data.frame(X, Y, Z)

summary(lm(Y ~ X, data = dt))
summary(lm(Y ~ X + Z, data = dt))

# Cool!
