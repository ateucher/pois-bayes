# Day 1
Andy Teucher  
November 20, 2014  


```r
library(dplyr)
library(ggplot2)
library(scales)
library(jaggernaut)
options(digits = 4)
```

## Exercise 1

Prior information told us it is *definitely* biased towards tails:


```r
model1 <- jags_model("
  model {
    theta ~ dunif(0,0.5)
    y ~ dbin(theta, n)
  }")
```

By specifying the prior distribution as bounded by (0, 0.5), it means that the final estimate of theta has to be less than 0.5, i.e., the probability of throwing a head is less than 0.5.


```r
data <- data.frame(n = 10, y = 3) # 10 trials, 3 tails
analysis1 <- jags_analysis(model1, data = data)
```

```
## Analysis converged (rhat:1)
```

```r
plot(analysis1)
```

![](Intro_and_trees_files/figure-html/unnamed-chunk-3-1.png) 

```r
coef(analysis1)
```

```
##       estimate lower  upper     sd error significance
## theta    0.297 0.102 0.4831 0.1033    64            0
```

## Black Cherry Trees


```r
data(trees)
ggplot(trees, aes(x = Girth, y = Volume)) + geom_point()
```

![](Intro_and_trees_files/figure-html/unnamed-chunk-4-1.png) 


#### To set up parallel processing (one for each chain), run the following code:


```r
if (getDoParWorkers() == 1) {
  registerDoParallel(4)
  opts_jagr(parallel = TRUE)
}
```


```r
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
```

```
## Resampling due to convergence failure (rhat:1.21)
## Analysis converged (rhat:1.03)
```

```r
plot(trees_analysis)
```

![](Intro_and_trees_files/figure-html/unnamed-chunk-6-1.png) 

```r
coef(trees_analysis)
```

```
##       estimate   lower   upper     sd error significance
## alpha  -36.338 -43.396 -29.451 3.4629    19            0
## beta     5.021   4.514   5.554 0.2551    10            0
## sigma    4.406   3.409   5.795 0.6201    27            0
```

## Exercise 2:


```r
auto_corr(trees_analysis)
```

```
##           alpha     beta     sigma
## Lag 1   0.88041  0.88450  0.198459
## Lag 5   0.50463  0.50682 -0.008219
## Lag 10  0.21445  0.21845 -0.014930
## Lag 50 -0.06992 -0.06524  0.022602
```

```r
cross_corr(trees_analysis)
```

```
##          alpha     beta    sigma
## alpha  1.00000 -0.97334  0.02447
## beta  -0.97334  1.00000 -0.02468
## sigma  0.02447 -0.02468  1.00000
```

The plots show "poor chain mixing"

Looking at at the plots and the outputs of auto_corr and cross_corr, ther is high autocorrelation in alpha and beta, and high cross-correlation betweenalpha and beta. The cross-correlation is intuitive because as you move the intercept up or down, the slope responds in the opposite direction. The autocorrelation is caused by the cross-correlation because in each MCMC step, the estimate of one parameter is updated based on the previous estimate of the other parameter, and back and forth...

## Exercise 3:

When `jaggernaut` tests for convergence, it evaluates it using `rhat` of the worst performing parameter.


```r
# ?convergence
convergence(trees_analysis, combine = FALSE)
```

```
##       convergence
## alpha        1.03
## beta         1.03
## sigma        1.00
```

```r
# Can get just specific parameters:
convergence(trees_analysis, parm = c("alpha", "beta"), combine = FALSE)
```

```
##       convergence
## alpha        1.03
## beta         1.03
```

Run `opts_jagr()` to see the jaggernaut options. Set with `opts_jagr(option = value)` (e.g., `opts_jagr(mode = "paper")` or `opts_jagr(nsamples = 5000)`).


## Exercise 4:
To run more iterations (e.g., to get better convergence):

N.B. Thinning 10,000 iterations down to 500 gets rid of the autocorrelation.


```r
trees_analysis <- jags_analysis(tree_model, data = trees, niter = 10^4)
```

```
## Analysis converged (rhat:1)
```

```r
plot(trees_analysis)
```

![](Intro_and_trees_files/figure-html/unnamed-chunk-9-1.png) 

```r
coef(trees_analysis)
```

```
##       estimate   lower   upper     sd error significance
## alpha  -36.687 -43.758 -30.047 3.5035    19            0
## beta     5.048   4.540   5.573 0.2586    10            0
## sigma    4.441   3.457   5.813 0.6277    27            0
```

```r
convergence(trees_analysis, combine = FALSE)
```

```
##       convergence
## alpha           1
## beta            1
## sigma           1
```

If you center the intercept on the x variable (girth), it will break the cross-correlation between the slope and intercept because you can now change the slope without affecting the intercept, and vice-versa.

## Exercise 5:


```r
## Option 1 Transform the variable:
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

trees$Girth <- trees$Girth - mean(trees$Girth)

trees_analysis <- jags_analysis(tree_model, data = trees)
```

```
## Analysis converged (rhat:1)
```

```r
plot(trees_analysis)
```

![](Intro_and_trees_files/figure-html/unnamed-chunk-10-1.png) 

```r
coef(trees_analysis)
```

```
##       estimate  lower  upper     sd error significance
## alpha   30.170 28.582 31.765 0.8088     5            0
## beta     5.075  4.589  5.602 0.2569    10            0
## sigma    4.436  3.443  5.757 0.5914    26            0
```

```r
auto_corr(trees_analysis)
```

```
##             alpha      beta   sigma
## Lag 1  -0.0450927 -0.036712 0.30669
## Lag 5  -0.0480811 -0.036315 0.03715
## Lag 10  0.0131601  0.001223 0.02109
## Lag 50 -0.0007313  0.022115 0.00490
```

```r
cross_corr(trees_analysis)
```

```
##           alpha      beta    sigma
## alpha  1.000000 -0.004765 -0.02609
## beta  -0.004765  1.000000  0.02817
## sigma -0.026091  0.028165  1.00000
```

```r
data(trees) # Reset trees after changing the Girth column

## Option 2 (in the BUGS code):
tree_model <- jags_model("
model {
  alpha ~ dnorm(0, 50^-2)
  beta ~ dnorm(0, 50^-2)
  sigma ~ dunif(0, 10)
  
  for (i in 1:length(Volume)) {
    eMu[i] <- alpha + beta * (Girth[i] - mean(Girth))
    Volume[i] ~ dnorm(eMu[i], sigma^-2)
  }
}")

trees_analysis <- jags_analysis(tree_model, data = trees)
```

```
## Analysis converged (rhat:1)
```

```r
plot(trees_analysis)
```

![](Intro_and_trees_files/figure-html/unnamed-chunk-10-2.png) 

```r
coef(trees_analysis)
```

```
##       estimate  lower  upper     sd error significance
## alpha   30.141 28.580 31.769 0.8056     5            0
## beta     5.068  4.547  5.613 0.2695    11            0
## sigma    4.446  3.462  5.892 0.6159    27            0
```

```r
auto_corr(trees_analysis)
```

```
##           alpha     beta    sigma
## Lag 1   0.02609  0.01016  0.36329
## Lag 5  -0.00760 -0.01670  0.01873
## Lag 10 -0.03555  0.07891 -0.02026
## Lag 50 -0.03013  0.02749 -0.02480
```

```r
cross_corr(trees_analysis)
```

```
##            alpha      beta      sigma
## alpha  1.0000000 0.0002657 -0.0256499
## beta   0.0002657 1.0000000  0.0008297
## sigma -0.0256499 0.0008297  1.0000000
```

```r
## Option 3:
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

select_data(tree_model) <- c("Volume", "Girth+") # The `+` centers the Girth parameter
trees_analysis <- jags_analysis(tree_model, data = trees)
```

```
## Analysis converged (rhat:1)
```

```r
plot(trees_analysis)
```

![](Intro_and_trees_files/figure-html/unnamed-chunk-10-3.png) 

```r
coef(trees_analysis)
```

```
##       estimate  lower  upper     sd error significance
## alpha   30.140 28.588 31.745 0.7975     5            0
## beta     5.072  4.541  5.595 0.2658    10            0
## sigma    4.410  3.463  5.688 0.5811    25            0
```

```r
auto_corr(trees_analysis)
```

```
##            alpha     beta    sigma
## Lag 1   0.009700 -0.03382  0.29745
## Lag 5  -0.012952  0.01844  0.04414
## Lag 10 -0.006907  0.00375  0.01456
## Lag 50 -0.008593  0.01210 -0.06306
```

```r
cross_corr(trees_analysis)
```

```
##          alpha      beta    sigma
## alpha 1.000000  0.004763  0.01597
## beta  0.004763  1.000000 -0.01221
## sigma 0.015967 -0.012209  1.00000
```

## Exercise 6:


```r
derived_code <- "data {
  for(i in 1:length(Volume)) { 
    prediction[i] <- alpha + beta * Girth[i]

    simulated[i] ~ dnorm(prediction[i], sigma^-2)

    D_observed[i] <- log(dnorm(Volume[i], prediction[i], sigma^-2))
    D_simulated[i] <- log(dnorm(simulated[i], prediction[i], sigma^-2))
  }
  residual <- (Volume - prediction) / sigma
  discrepancy <- sum(D_observed) - sum(D_simulated)
}"

predicted <- predict(trees_analysis, newdata = "Girth", derived_code = derived_code)

new.data <- data.frame(Girth = 8)

predicted2 <- predict(trees_analysis, newdata = new.data, derived_code = derived_code)
predicted2
```

```
##   Girth Height Volume estimate  lower upper    sd error significance
## 1     8     76  30.17    3.519 0.2256 6.656 1.604    91       0.0347
```

The 95% prediction interval is 0.2256 to 6.6558

## Exercise 9:

To fit the allometric relationship, log the parameters in the `select_data()` call


```r
data(trees)

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

select_data(tree_model) <- c("log(Volume)", "log(Girth)+")
trees_analysis <- jags_analysis(tree_model, data = trees)
```

```
## Analysis converged (rhat:1)
```

```r
plot(trees_analysis)
```

![](Intro_and_trees_files/figure-html/unnamed-chunk-12-1.png) 

```r
coef(trees_analysis)
```

```
##       estimate   lower  upper      sd error significance
## alpha   3.2715 3.22945 3.3144 0.02164     1            0
## beta    2.1979 2.00250 2.3826 0.09671     9            0
## sigma   0.1209 0.09235 0.1572 0.01687    27            0
```

```r
derived_code <- "data {
  for(i in 1:length(Volume)) { 
    prediction[i] <- alpha + beta * Girth[i]

    simulated[i] ~ dnorm(prediction[i], sigma^-2)

    D_observed[i] <- log(dnorm(Volume[i], prediction[i], sigma^-2))
    D_simulated[i] <- log(dnorm(simulated[i], prediction[i], sigma^-2))
  }
  residual <- (Volume - prediction) / sigma
  discrepancy <- sum(D_observed) - sum(D_simulated)
}"

predicted <- predict(trees_analysis, newdata = "Girth", derived_code = derived_code)
simulated <- predict(trees_analysis, parm = "simulated", newdata = "Girth", 
                     derived_code = derived_code)

## Need to exponentiate the predicted values to get them back into regular parameter space:

gp <- ggplot(predicted, aes(x = Girth, y = exp(estimate))) + 
  geom_point(data = dataset(trees_analysis), aes(y = Volume)) + 
  geom_line() + 
  geom_line(aes(y = exp(lower)), linetype = "dashed") + 
  geom_line(aes(y = exp(upper)), linetype = "dashed") + 
  geom_line(data = simulated, aes(y = lower), linetype = "dotted") + 
  geom_line(data = simulated, aes(y = upper), linetype = "dotted") + 
  scale_y_continuous(name = "Volume")

gp
```

![](Intro_and_trees_files/figure-html/unnamed-chunk-12-2.png) 

You can also specify `log(predicted)` to generate back-transformed predicted values and use `dlnorm` to generate the simulated data in the derived code, :


```r
data(trees)

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

select_data(tree_model) <- c("log(Volume)", "log(Girth)+")
trees_analysis <- jags_analysis(tree_model, data = trees)
```

```
## Analysis converged (rhat:1)
```

```r
plot(trees_analysis)
```

![](Intro_and_trees_files/figure-html/unnamed-chunk-13-1.png) 

```r
coef(trees_analysis)
```

```
##       estimate   lower  upper      sd error significance
## alpha   3.2731 3.22863 3.3167 0.02240     1            0
## beta    2.2002 2.01754 2.3850 0.09370     8            0
## sigma   0.1206 0.09359 0.1581 0.01626    27            0
```

```r
derived_code <- "data {
  for(i in 1:length(Volume)) { 
    log(prediction[i]) <- alpha + beta * Girth[i]

    simulated[i] ~ dlnorm(log(prediction[i]), sigma^-2)

    D_observed[i] <- log(dnorm(Volume[i], prediction[i], sigma^-2))
    D_simulated[i] <- log(dnorm(simulated[i], prediction[i], sigma^-2))
  }
  residual <- (Volume - prediction) / sigma
  discrepancy <- sum(D_observed) - sum(D_simulated)
}"

predicted <- predict(trees_analysis, newdata = "Girth", derived_code = derived_code)
simulated <- predict(trees_analysis, parm = "simulated", newdata = "Girth", 
                     derived_code = derived_code)

## Need to exponentiate the predicted values to get them back into regular parameter space:

gp <- ggplot(predicted, aes(x = Girth, y = estimate)) + 
  geom_point(data = dataset(trees_analysis), aes(y = Volume)) + 
  geom_line() + 
  geom_line(aes(y = lower), linetype = "dashed") + 
  geom_line(aes(y = upper), linetype = "dashed") + 
  geom_line(data = simulated, aes(y = lower), linetype = "dotted") + 
  geom_line(data = simulated, aes(y = upper), linetype = "dotted") + 
  scale_y_continuous(name = "Volume")

gp
```

![](Intro_and_trees_files/figure-html/unnamed-chunk-13-2.png) 

## Exercise 10:


```r
data(trees)

tree_model <- jags_model("
model {
  alpha ~ dnorm(0, 50^-2)
  beta ~ dnorm(0, 50^-2)
  betaHeight ~ dnorm(0, 50^-2)
  sigma ~ dunif(0, 10)
  
  for (i in 1:length(Volume)) {
    eMu[i] <- alpha + beta * Girth[i] + betaHeight * Height[i]
    Volume[i] ~ dnorm(eMu[i], sigma^-2)
  }
}")

select_data(tree_model) <- c("log(Volume)", "log(Girth)+", "log(Height)+")
trees_analysis <- jags_analysis(tree_model, data = trees)
```

```
## Analysis converged (rhat:1.01)
```

```r
plot(trees_analysis)
```

![](Intro_and_trees_files/figure-html/unnamed-chunk-14-1.png) 

```r
coef(trees_analysis)
```

```
##            estimate   lower  upper      sd error significance
## alpha       3.27198 3.24208 3.3020 0.01520     1            0
## beta        1.98355 1.84042 2.1401 0.07743     8            0
## betaHeight  1.11387 0.71211 1.5144 0.20486    36            0
## sigma       0.08441 0.06537 0.1111 0.01177    27            0
```

```r
derived_code <- "data {
  for(i in 1:length(Volume)) { 
    log(prediction[i]) <- alpha + beta * Girth[i] + betaHeight * Height[i]

    simulated[i] ~ dlnorm(log(prediction[i]), sigma^-2)

    D_observed[i] <- log(dnorm(Volume[i], prediction[i], sigma^-2))
    D_simulated[i] <- log(dnorm(simulated[i], prediction[i], sigma^-2))
  }
  residual <- (Volume - prediction) / sigma
  discrepancy <- sum(D_observed) - sum(D_simulated)
}"

predicted <- predict(trees_analysis, newdata = c("Girth", "Height"), 
                     derived_code = derived_code, length_out = 10)

simulated <- predict(trees_analysis, parm = "simulated", newdata = "Girth", 
                     derived_code = derived_code, length_out = 10)

gp <- ggplot(predicted, aes(x = Girth, y = estimate)) + 
  facet_wrap(~ Height) + 
  geom_point(data = dataset(trees_analysis), aes(y = Volume)) + 
  geom_line() + 
  geom_line(aes(y = lower), linetype = "dashed") + 
  geom_line(aes(y = upper), linetype = "dashed") + 
  geom_line(data = simulated, aes(y = lower), linetype = "dotted") + 
  geom_line(data = simulated, aes(y = upper), linetype = "dotted") + 
  scale_y_continuous(name = "Volume")

gp
```

![](Intro_and_trees_files/figure-html/unnamed-chunk-14-2.png) 

As the parameter estimate for Height is different from zero, it is a likely addition to the model.

