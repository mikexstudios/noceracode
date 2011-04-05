#!/usr/bin/env Rscript

args <- commandArgs(TRUE)
n <- as.integer(args[1])

input <- sprintf('cp%s_%d.txt', '%d', n)
output <- sprintf('multicp_%d.pdf', n)

pdf(output)

par(mfrow = c(3,3)) #row, col

for(i in seq(1, 13)) {
     csv <- sprintf(input, i)
     cp <- read.csv(file = csv, skip = 18)
     #Because the second plot is smaller, we need to adjust the y-axis range here.
     plot(cp$Time.sec, cp$Potential.V,
          main = csv,
          xlab = "t (s)", ylab = "E (V)",
          #type = "l",
          cex = 0.4, #size of the points
          #ylim = c(0.85, 1.31)
          )
}

#Flush to file
dev.off()
