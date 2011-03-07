#!/usr/bin/env Rscript

pdf('multicp_2.pdf')

par(mfrow = c(3,3)) #row, col

for(i in seq(1, 13)) {
     csv <- sprintf("cp%d_2.txt", i)
     cp <- read.csv(file = csv, skip = 18)
     #Because the second plot is smaller, we need to adjust the y-axis range here.
     plot(cp$Time.sec, cp$Potential.V,
          main = csv,
          xlab = "t (s)", ylab = "E (V)",
          #type = "l",
          cex = 0.4 #size of the points
          )
}

#Flush to file
dev.off()
