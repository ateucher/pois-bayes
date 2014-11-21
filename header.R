library(dplyr)
library(ggplot2)
library(scales)
library(jaggernaut)
options(digits = 4)

if (getDoParWorkers() == 1) {
  registerDoParallel(4)
  opts_jagr(parallel = TRUE)
}