#!/usr/bin/env Rscript
library('Hmisc')

#This plot w/h ratio was determined through CHI instruments' plot.
pdf('cv.pdf', width = 9, height = 7)

#Parameters
current_rescale_factor <- 1e-4 #make sure to update the ylab too!
potential_reference_correction <- 0.197 #added to potential

#Read in data and rescale current
cv <- read.csv(file='pH_01.csv', header = TRUE)
cv$current_s = cv$current/current_rescale_factor
cv$potential_c = cv$potential + potential_reference_correction

#Shift axis labels closer to plot since ticks have been moved in.
#Must come before the plot command.
#See: http://www.programmingr.com/content/controlling-margins-and-axes-oma-and-mgp
par(mgp = c(1.9, 0.3, 0))
#Add extra margin to the bottom of plot since we will include double x-axis there.
#c(bottom, left, top, right)
par(mar=c(6,4,1,1))

plot(cv$potential_c, cv$current_s, 
     #main="Tafel plot", 
     #xlab = expression(italic('E') * " (V vs. Ag/AgCl)"), 
     xlab = '',
     ylab = expression(italic('i') * " (x " *  10^{-4} * " A)"),
     type='l', #line plot
     tck = 0.03,
     #family = 'serif',
     cex.lab = 1.5,
     cex.axis = 1.3,
     xlim = rev(range(cv$potential_c)), #reverse x-axis
     ylim = range(-1, 0.3),
     lwd = 5, #larger line width
     col = '#6b1901'
    )

box(lwd = 3)

#Left axis, inner tick mark with tck, thicker line with lwd.
axis(2, at = axTicks(2), label = FALSE, lwd = 2, tck = 0.03)
axis(1, at = axTicks(1), label = FALSE, lwd = 2, tck = 0.03)
mtext(1, text = expression(italic('E') * " (V vs. NHE)      "), 
      line = 1.5)
#mtext("eta (V)", side=4, line=2)
minor.tick(nx=2, ny=2, tick.ratio=-1)
#TODO: Figure out how to increase line width of minor ticks!

#Add another axis at the bottom for NHE
axis(1, at = axTicks(1), 
     label = round(axTicks(1) - potential_reference_correction, digits = 3), 
     lwd = 2,
     tck = 0.03,
     line = 3.3)
mtext(1, text = expression(italic('E') * " (V vs. Ag/AgCl)"),
      line = 4.8)

#Adding subsequent plots
cv <- read.csv(file='pH_02.csv', header = TRUE)
cv$current_s = cv$current/current_rescale_factor
cv$potential_c = cv$potential + potential_reference_correction
lines(cv$potential_c, cv$current_s, 
      lwd = 5,
      col = '#9d2401'
     )

cv <- read.csv(file='pH_03.csv', header = TRUE)
cv$current_s = cv$current/current_rescale_factor
cv$potential_c = cv$potential + potential_reference_correction
lines(cv$potential_c, cv$current_s, 
      lwd = 5,
      col = '#d03001'
     )

cv <- read.csv(file='pH_04.csv', header = TRUE)
cv$current_s = cv$current/current_rescale_factor
cv$potential_c = cv$potential + potential_reference_correction
lines(cv$potential_c, cv$current_s, 
      lwd = 5,
      col = '#fe4b17'
     )

cv <- read.csv(file='pH_05.csv', header = TRUE)
cv$current_s = cv$current/current_rescale_factor
cv$potential_c = cv$potential + potential_reference_correction
lines(cv$potential_c, cv$current_s, 
      lwd = 5,
      col = '#fe734a'
     )

#cv <- read.csv(file='pH_06.csv', header = TRUE)
#cv$current_s = cv$current/current_rescale_factor
#lines(cv$potential, cv$current_s, lwd = 4)
#
#cv <- read.csv(file='pH_07.csv', header = TRUE)
#cv$current_s = cv$current/current_rescale_factor
#lines(cv$potential, cv$current_s, lwd = 4)
#
#cv <- read.csv(file='pH_08.csv', header = TRUE)
#cv$current_s = cv$current/current_rescale_factor
#lines(cv$potential, cv$current_s, lwd = 4)
#
#cv <- read.csv(file='pH_09.csv', header = TRUE)
#cv$current_s = cv$current/current_rescale_factor
#lines(cv$potential, cv$current_s, lwd = 4)


#Flush to file
dev.off()
