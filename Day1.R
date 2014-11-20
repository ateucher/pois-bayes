library(dplyr)
library(ggplot2)
library(scales)
library(jaggernaut)
options(digits = 4)

## Exercise 1
model1 <- jags_model("
  model {
    theta ~ dunif(0,0.5)
    y ~ dbin(theta, n)
  }")
# By specifying the prior distribution as bounded by (0, 0.5), it means that the final
# estimate of theta has to be less than 0.5, i.e., the probability of throwing a head
# is less than 0.5 (note, prior info told us it is *definitely* biased towards tails)

data <- data.frame(n = 10, y = 3) # 10 trials, 3 tails
analysis1 <- jags_analysis(model1, data = data)
plot(analysis1)
coef(analysis1)

## Black Cherry Trees

data(trees)
ggplot(trees, aes(x = Girth, y = Volume)) + geom_point()

## To set up parallel processing (one for each chain), run the following code:
if (getDoParWorkers() == 1) {
  registerDoParallel(4)
  opts_jagr(parallel = TRUE)
}

tree_model <- jags_model("
model {
  alpha ~ dnorm(0, 50^-2)
  beta ~ dnorm(0, 50^-2)
  sigma ~ dunif(0, 10)
  
  for (i in 1:length(Volume)) {
    eMu[i] <- alpha + beta * Girth[i]
    Volume[i] ~ dnorm(eMu[i], sigma^-2)
  }
}")

trees_analysis <- jags_analysis(tree_model, data = trees)
plot(trees_analysis)
coef(trees_analysis)

## Exercise 2:
auto_corr(trees_analysis)
cross_corr(trees_analysis)
## Looking at at the plots and the outputs of auto_corr and cross_corr, 
## ther is high autocorrelation in alpha and beta, and high cross-correlation between
## alpha and beta. The cross-correlation is intuitive because as you move the 
## intercept up or down, the slope responds in the opposite direction. The 
## autocorrelation is caused by the cross-correlation because in each MCMC step, 
## the estimate of one parameter is updated based on the previous estimate of the 
## other parameter, and back and forth...





graphics.off()
rm(list = ls())