#!/usr/bin/env Rscript

pdf('tafel.pdf')
t1 <- read.csv(file='test.plot', header = FALSE)
plot(t1$V1, t1$V2, main="Tafel plot", xlab="log(i)", ylab="E (V)")

#We only want to select a subset ot points
lt1 <- t1[2:9,c('V1','V2')]
fit <- lm(lt1$V2 ~ lt1$V1)
abline(fit, col='red')
summary(fit)

#Flush to file
dev.off()
