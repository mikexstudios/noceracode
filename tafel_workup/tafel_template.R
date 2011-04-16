#!/usr/bin/env Rscript

pdf('tafel_#{pass}.pdf')
t1 <- read.csv(file='tafel_#{pass}.csv', header = FALSE)
plot(t1$V1, t1$V2, 
     main="#{plot_title}", 
     xlab="log(i A/cm^2)", ylab="E (V vs Ag/AgCl)")

# PLOT SETTINGS (do not remove this line)


#EXAMPLE: If you want to select a subset of points for line fitting.

#lt1 <- t1[2:6,c('V1','V2')]
#fit <- lm(lt1$V2 ~ lt1$V1)
#abline(fit, col='red')
#summary(fit)
#
#lt1 <- t1[7:13,c('V1','V2')]
#fit <- lm(lt1$V2 ~ lt1$V1)
#abline(fit, col='blue')
#summary(fit)

#EXAMPLE: If you need to remove a point because it is an outlier, use the
#    following syntax. Note that the indicies for the points will be shifted.
#    Make sure to insert this before one of the line-fittings.
#t1 <- merge(t1[1:9,], t1[11:13,], all = TRUE, sort = FALSE)

#EXAMPLE: If you want to do an overall fit.

#lt1 <- t1[,c('V1','V2')]
#fit <- lm(lt1$V2 ~ lt1$V1)
#abline(fit, col='blue')
#summary(fit)


# END PLOT SETTINGS (do not remove this line)


#Flush to file
dev.off()
