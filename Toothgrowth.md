# Toothgrowth
Andy Teucher  
November 20, 2014  


```r
source("header.R")
```

```
## 
## Attaching package: 'dplyr'
## 
## The following object is masked from 'package:stats':
## 
##     filter
## 
## The following objects are masked from 'package:base':
## 
##     intersect, setdiff, setequal, union
## 
## Loading required package: foreach
## Loading required package: doParallel
## Loading required package: iterators
## Loading required package: parallel
```



```r
data(ToothGrowth)

model1 <- jags_model("model {
  for(i in 1:nsupp) {
    alpha[i] ~ dnorm(0, 40^-2)
  }
  beta ~ dnorm(0, 20^-2)
  sigma ~ dunif(0, 20)

  for(i in 1:length(len)) { 
    eLen[i] <- alpha[supp[i]] + beta * dose[i]
    len[i] ~ dnorm(eLen[i], sigma^-2)
  } 
}",
derived_code  = " data{
  for(i in 1:length(len)) { 
    prediction[i] <- alpha[supp[i]] + beta * dose[i]
  }
  residual <- (len - prediction) / sigma
}")

analysis1 <- jags_analysis(model1, data = ToothGrowth)
```

```
## Analysis converged (rhat:1.01)
```

```r
coef(analysis1)
```

```
##          estimate lower  upper     sd error significance
## alpha[1]    9.284 6.659 11.817 1.2990    28            0
## alpha[2]    5.620 3.166  8.144 1.2660    44            0
## beta        9.736 8.073 11.476 0.8636    17            0
## sigma       4.319 3.589  5.216 0.4113    19            0
```

```r
plot(analysis1)
```

![](Toothgrowth_files/figure-html/unnamed-chunk-2-1.png) 

```r
prediction <- predict(analysis1, newdata = c("supp", "dose"))

gp <- ggplot(data = prediction, aes(x = dose, y = estimate, color = supp, 
    shape = supp))
gp <- gp + geom_point(data = dataset(analysis1), aes(y = len))
gp <- gp + geom_line()
gp <- gp + scale_y_continuous(name = "len")

gp
```

![](Toothgrowth_files/figure-html/unnamed-chunk-2-2.png) 

```r
residuals <- residuals(analysis1)
residuals$fitted <- fitted(analysis1)$estimate

qplot(fitted, estimate, color = supp, shape = supp, data = residuals, xlab = "Fitted", 
    ylab = "Residual") + geom_hline(yintercept = 0)
```

![](Toothgrowth_files/figure-html/unnamed-chunk-2-3.png) 

## Exercise 11:


```r
predictive_check(analysis1, newdata = "", 
                 derived_code = "data{ discrepancy <- alpha[1] - alpha[2]}")
```

```
##             estimate lower upper    sd error significance
## discrepancy    3.664 1.445 5.883 1.152    61            0
```

```r
## OR reparameterize the model by setting a base case and an effect
```


## Exercise 13:


```r
data(ToothGrowth)

tg_ancova <- jags_model("model {
  for(i in 1:nsupp) {
    alpha[i] ~ dnorm(0, 40^-2)
  }
  beta ~ dnorm(0, 20^-2)
  sigma ~ dunif(0, 20)

  for(i in 1:length(len)) { 
    eLen[i] <- alpha[supp[i]] + beta * dose[i]
    len[i] ~ dnorm(eLen[i], sigma^-2)
  } 
}",
derived_code  = " data{
  for(i in 1:length(len)) { 
    prediction[i] <- alpha[supp[i]] + beta * dose[i]
  }
  residual <- (len - prediction) / sigma
}", 
model_id = "ancova")

tg_regression <- jags_model("model {
  alpha ~ dnorm(0, 40^-2)
  beta ~ dnorm(0, 20^-2)
  sigma ~ dunif(0, 20)

  for(i in 1:length(len)) { 
    eLen[i] <- alpha + beta * dose[i]
    len[i] ~ dnorm(eLen[i], sigma^-2)
  } 
}",
derived_code  = " data{
  for(i in 1:length(len)) { 
    prediction[i] <- alpha + beta * dose[i]
  }
  residual <- (len - prediction) / sigma
}", 
model_id = "regression")

tg_anova <- jags_model("model {
  for(i in 1:nsupp) {
    alpha[i] ~ dnorm(0, 40^-2)
  }
  sigma ~ dunif(0, 20)

  for(i in 1:length(len)) { 
    eLen[i] <- alpha[supp[i]]
    len[i] ~ dnorm(eLen[i], sigma^-2)
  } 
}",
derived_code  = " data{
  for(i in 1:length(len)) { 
    prediction[i] <- alpha[supp[i]]
  }
  residual <- (len - prediction) / sigma
}", 
model_id = "anova")

tg_ancova_int <- jags_model("model {
  for(i in 1:nsupp) {
    alpha[i] ~ dnorm(0, 40^-2)
    beta[i] ~ dnorm(0, 20^-2)
  }
  sigma ~ dunif(0, 20)

  for(i in 1:length(len)) { 
    eLen[i] <- alpha[supp[i]] + beta[supp[i]] * dose[i]
    len[i] ~ dnorm(eLen[i], sigma^-2)
  } 
}",
derived_code  = " data{
  for(i in 1:length(len)) { 
    prediction[i] <- alpha[supp[i]] + beta[supp[i]] * dose[i]
  }
  residual <- (len - prediction) / sigma
}", 
model_id = "ancova_int")

models <- combine(tg_ancova, tg_ancova_int, tg_anova, tg_regression)

tg_analysis <- jags_analysis(models, data = ToothGrowth)
```

```
## ancova
## Analysis converged (rhat:1)
## ancova_int
## Analysis converged (rhat:1.02)
## anova
## Analysis converged (rhat:1)
## regression
## Analysis converged (rhat:1)
```

```r
prediction <- predict(tg_analysis, newdata = c("supp", "dose"), 
                      model_id = "regression")

gp <- gp %+% prediction # updates the data in the gp object
```

## Exercise 15:


```r
model_ids <- model_id(tg_analysis)

predictions <- data.frame()

for (id in model_ids) {
  pred <- predict(tg_analysis, newdata = c("supp", "dose"), model_id = id, 
                  base = data.frame(supp = "VC", base = 0.5))
  
  pred$id <- id
  
  predictions <- rbind(predictions, pred)
  
  }

gp <- ggplot(predictions, aes(x = dose, y = estimate, color = supp, 
                              shape = supp)) +
  facet_wrap(~ id) +
  geom_line() + 
  scale_y_continuous(name = "Effect on len (%)", labels = percent)

plot(gp)
```

![](Toothgrowth_files/figure-html/unnamed-chunk-5-1.png) 

