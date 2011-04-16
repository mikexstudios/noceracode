#!/usr/bin/env Rscript

pdf('tafel_combined.pdf')

#FIRST PLOT (do not remove)
#Pass: #{pass}
t1 <- read.csv(file='tafel_#{pass}.csv', header = FALSE)
#We may need to adjust the y-axis range (change ylim).
plot(t1$V1, t1$V2, col = "#{color}", 
     main="#{plot_title}", 
     xlab="log(i A/cm^2)", ylab="E (V vs Ag/AgCl)",
     ylim = c(#{$combined_ylim[0]}, #{$combined_ylim[1]}))

#{linear_fit}
#END FIRST PLOT

#SUBSEQUENT PLOTS (do not remove)
#Pass: #{pass}
t1 <- read.csv(file='tafel_#{pass}.csv', header = FALSE)
points(t1$V1, t1$V2, col='#{color}')

#{linear_fit}
#END SUBSEQUENT PLOTS (do not remove)

#LEGEND (do not remove)
legend("topleft",
       legend = c(
              #{labels}
       ),
       col = c(
              #{colors}
       ),
       lty = 1)
#END LEGEND

#Flush to file
dev.off()
