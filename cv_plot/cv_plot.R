#!/usr/bin/env Rscript
library('Hmisc')

pdf('cv.pdf')
cv <- read.csv(file='cv9.txt', header = TRUE)

#Rescale current
cv$current_s = cv$current/1e-4

#Shift axis labels closer to plot since ticks have been moved in.
#See: http://www.programmingr.com/content/controlling-margins-and-axes-oma-and-mgp
par(mgp = c(1.9, 0.3, 0))

plot(cv$potential, cv$current_s, 
     #main="Tafel plot", 
     xlab = expression(italic('E') * " (V vs. Ag/AgCl)"), 
     ylab = expression(italic('i') * " (A)"),
     type='l', #line plot
     lwd = 4, #larger line width
     xlim = rev(range(cv$potential)), #reverse x-axis
     tck = 0.03,
     #family = 'serif',
     cex.lab = 1.5,
     cex.axis = 1.3
    )

box(lwd = 3)

#Left axis, inner tick mark with tck, thicker line with lwd.
axis(2, at = axTicks(2), label = FALSE, lwd = 2, tck = 0.03)
axis(1, at = axTicks(1), label = FALSE, lwd = 2, tck = 0.03)
#mtext("eta (V)", side=4, line=2)
minor.tick(nx=2, ny=2, tick.ratio=-1)
#TODO: Figure out how to increase line width of minor ticks!


#We only want to select a subset ot points
#lt1 <- t1[2:9,c('V1','V2')]
#fit <- lm(lt1$V2 ~ lt1$V1)
#abline(fit, col='red')
#summary(fit)

#Flush to file
dev.off()
