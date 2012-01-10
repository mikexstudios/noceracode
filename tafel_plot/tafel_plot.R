#!/usr/bin/env Rscript

pdf('tafel.pdf')
t1 <- read.csv(file='tafel_1.csv', header = FALSE)
#Add extra margin to the right side of the plot
par(mar=c(4,4,4,4))
plot(t1$V1, t1$V2, main="Tafel plot", xlab="log(i)", ylab="E (V)")

axis(4, at = axTicks(2), label = axTicks(2) - 0.6)
mtext("eta (V)", side=4, line=2)

#We only want to select a subset ot points
#lt1 <- t1[2:9,c('V1','V2')]
#fit <- lm(lt1$V2 ~ lt1$V1)
#abline(fit, col='red')
#summary(fit)

#Flush to file
dev.off()
