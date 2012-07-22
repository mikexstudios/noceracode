plot.cv.xlab = ''
plot.cv.ylab = ''
plot.cv.setup <- function(xlab = '', ylab = '') {
    #Shift axis labels closer to plot since ticks have been moved in.
    #Must come before the plot command.
    #See: http://www.programmingr.com/content/controlling-margins-and-axes-oma-and-mgp
    #par(mgp = c(4.6, 1.5, 0))
    #par(mgp = c(0, 1.5, 0))

    #Add extra margin to the plot since we increased axis label sizes
    #c(bottom, left, top, right)
    #NOTE: We assume that the aspect ratio of the plot is: 9 by 7.
    par(mar=c(7,8,2,1))

    par(
        lwd = 5, #larger line width
        cex.lab = 3.0, #make axis annotation larger
        cex.axis = 2.9 #make axis label larger
        )
    
    plot.cv.xlab <<- xlab
    plot.cv.ylab <<- ylab
}

plot.cv.is_first_plot = TRUE
plot.cv <- function(...) {
    if (plot.cv.is_first_plot) {
        plot(...,
             axes = FALSE, #we will make our own axes
             ann = FALSE, #we will make our own axes annotation
             type = 'l', #line plot
             tck = 0, #we will make our own tick marks
            )
        
        #Setup post-plotting customizations
        box(lwd = 4)

        #Left axis, inner tick mark with tck, thicker line with lwd.
        #axis(2, at = axTicks(2), label = FALSE, lwd = 4, tck = 0.05)
        axis(2, at = axTicks(2), label = TRUE, lwd = 4, tck = 0.05, cex.axis = 2.9)
        mtext(side = 2, text = plot.cv.ylab,
              line = 3.5, cex = 3.0)
        
        #Bottom axis
        axis(1, at = axTicks(1), label = TRUE, lwd = 4, tck = 0.05, cex.axis = 2.9,
             mgp = c(5.6, 1.9, 0))
        mtext(side = 1, text = plot.cv.xlab
              line = 5.5, cex = 3.0)
        
        minor.tick(nx=2, ny=2, tick.ratio=-2, lwd = 3)

        #Add another axis at the bottom for NHE
        #axis(1, at = axTicks(1), 
        #     label = round(axTicks(1) - potential_reference_correction, digits = 3), 
        #     lwd = 2,
        #     tck = 0.03,
        #     line = 3.3)
        #mtext(1, text = expression(italic('E') * " (V vs. Ag/AgCl)"),
        #      line = 4.8)

        plot.cv.is_first_plot <<- FALSE #need double arrow to overwrite global
    } else {
        lines(...)
    }
}

plot.cv.legend <- function(...) {
    legend(...,
           cex = 1.9,
           lwd = 3, 
           inset = c(0.03, 0.00),
           seg.len = 3, #longer lines
           bty = 'n')
}
