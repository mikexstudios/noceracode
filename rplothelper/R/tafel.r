plot.tafel.xlab = ''
plot.tafel.ylab = ''
plot.tafel.setup <- function() {
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
        lwd = 7, #line width of points
        cex.lab = 3.0, #make axis annotation larger
        cex.axis = 2.9 #make axis label larger
        )
}

plot.tafel.is_first_plot = TRUE
plot.tafel <- function(...) {
    if (plot.tafel.is_first_plot) {
        plot(...,
             axes = FALSE, #we will make our own axes
             ann = FALSE, #we will make our own axes annotation
             type = 'p', #points
             tck = 0, #we will make our own tick marks
             cex = 5.0 #point size
            )
        
        #Setup post-plotting customizations
        box(lwd = 4)

        #Left axis, inner tick mark with tck, thicker line with lwd.
        #axis(2, at = axTicks(2), label = FALSE, lwd = 4, tck = 0.05)
        axis(2, at = axTicks(2), label = TRUE, lwd = 4, tck = 0.05, cex.axis = 2.9)
        mtext(side = 2, text = plot.tafel.ylab,
              line = 3.5, cex = 3.0)
        
        #Bottom axis
        axis(1, at = axTicks(1), label = TRUE, lwd = 4, tck = 0.05, cex.axis = 2.9,
             mgp = c(5.6, 1.9, 0))
        mtext(side = 1, text = plot.tafel.xlab,
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

        plot.tafel.is_first_plot <<- FALSE #need double arrow to overwrite global
    } else {
        points(...,
               cex = 4.0)
    }
}

plot.tafel.legend <- function(..., lwd = 6, cex = 2.5, seg.len = 3) {
    legend(...,
           cex = cex,
           lwd = lwd, 
           seg.len = seg.len, #longer lines
           bty = 'n')
}


tafel.linear_fit <- function(iac.log, potential, range = TRUE, color = 'black')
{
    if(is.numeric(range)) {
        x = iac.log[range]
        y = potential[range]
    } else {
        x = iac.log
        y = potential
    }

    fit = lm(y ~ x)
    intercept = fit$coefficients['(Intercept)']
    slope = fit$coefficients['x']

    abline(intercept, slope, 
           lwd = 8, #larger line width
           col = color)

    #Get coefficients and R^2 values
    summ = summary(fit)
    coefficients = summ['coefficients'][[1]]
    slope.stdev = coefficients['x', 'Std. Error']
    rsq = summ['r.squared'][[1]]

    summ = data.frame(slope = slope,
                      slope.stdev = slope.stdev,
                      intercept = intercept,
                      rsq = rsq * 100)
    return(summ)
}
