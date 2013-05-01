plot.tafel.xlab = ''
plot.tafel.ylab = ''
plot.tafel.setup <- function(mar=c(7,8,2,1)) {
    #Shift axis labels closer to plot since ticks have been moved in.
    #Must come before the plot command.
    #See: http://www.programmingr.com/content/controlling-margins-and-axes-oma-and-mgp
    #par(mgp = c(4.6, 1.5, 0))
    #par(mgp = c(0, 1.5, 0))

    #Add extra margin to the plot since we increased axis label sizes
    #c(bottom, left, top, right)
    #NOTE: We assume that the aspect ratio of the plot is: 9 by 7.
    par(mar=mar)

    par(
        lwd = 7, #line width of points
        cex.lab = 3.0, #make axis annotation larger
        cex.axis = 2.9 #make axis label larger
        )
}

plot.tafel.is_first_plot = TRUE
plot.tafel <- function(..., cex = 4.5, type = 'p', is_y_labels = TRUE, 
                       is_y_ticks = TRUE, is_minor_ticks = TRUE, 
                       y_label_line = 5.0, is_x_labels = TRUE, is_x_ticks = TRUE) {
    if (plot.tafel.is_first_plot) {
        plot(...,
             axes = FALSE, #we will make our own axes
             ann = FALSE, #we will make our own axes annotation
             type = type, #points
             tck = 0, #we will make our own tick marks
             cex = cex, #point size
             xaxs = 'i',
             yaxs = 'i'
            )
        
        #Setup post-plotting customizations
        box(lwd = 4)

        if (is_y_labels) {
            #Left axis, inner tick mark with tck, thicker line with lwd.
            axis(side = 2, at = axTicks(2), label = TRUE, lwd = 3, tck = 0.05,
                 cex.axis = 2.8, las = 1) #make y-axis labels horizontal
            mtext(side = 2, text = plot.tafel.ylab,
                  line = y_label_line, cex = 3.0, las = 0) #make y-axis labels parallel again
        } else if (is_y_ticks) {
            axis(side = 2, at = axTicks(2), label = FALSE, lwd = 3, tck = 0.05,
                 cex.axis = 2.8, las = 1) #make y-axis labels horizontal
        }
        
        #Bottom axis
        if (is_x_labels) {
            axis(side = 1, at = axTicks(1), label = TRUE, lwd = 3, tck = 0.05,
                 cex.axis = 2.8, mgp = c(5.6, 1.9, 0))
            mtext(side = 1, text = plot.tafel.xlab, line = 5.5, cex = 3.0)
        } else if (is_x_ticks) {
            axis(side = 1, at = axTicks(1), label = TRUE, lwd = 3, tck = 0.05,
                 cex.axis = 2.8, mgp = c(5.6, 1.9, 0))
        }
            
        if (is_minor_ticks) {
            minor.tick(nx=2, ny=2, tick.ratio=-2, lwd = 2.5)
        }

        plot.tafel.is_first_plot <<- FALSE #need double arrow to overwrite global
    } else {
        points(...,
               type = type,
               cex = cex)
    }
}

plot.tafel.legend <- function(..., lwd = 6, cex = 2.5, seg.len = 3) {
    legend(...,
           cex = cex,
           lwd = lwd, 
           seg.len = seg.len, #longer lines
           bty = 'n')
}

plot.tafel.add_overpotentials <- function(E_water_ox_standard, is_minor_ticks = TRUE) {
    #NOTE: User must override plot.tafel.setup with extra margin on
    #      the right side of the plot!
    axis(4, at = axTicks(2), 
         tck = 0.05,
         lwd = 3,
         cex.axis = 2.8,
         mgp = c(5.6, 1.1, 0),
         label = round((axTicks(2) - E_water_ox_standard) * 1000), 
         las = 1) #make y-axis labels horizontal

    if (is_minor_ticks) {
        #Use modded minor.tick to add ticks to right axis.
        minor.tick(nx=2, ny=2, tick.ratio=-2, side = 4, lwd = 2.5)
    }

    mtext(expression(eta ~ "/ mV"), side = 4, line = 7.8, cex = 3.0,
          las = 0) #make label vertical again
    
    #The problem with mtext is that we can't rotate that label. Thus,
    #manually calculate the position of the mtext
    #Get plot coordinates and find the middle coordinate of the right axis.
    #plot_coords = par('usr', no.readonly = TRUE)
    #plot.width.x = plot_coords[2] - plot_coords[1]
    #plot.width.y = plot_coords[4] - plot_coords[3]
    #x2 = plot_coords[2]
    #y_center = plot.width.y/2
    ##Get typical string line height
    #line_height = (par('mai')[1]/par('mar')[1])/strheight('test','inches', cex = 3.0)
    ##line = 5.5
    #line = -0.5
    #y_center = 1.1
    #print(par('usr'))
    #text(x = x2 + (0.5 + line) * line_height, y = y_center, 
    #     expression(eta ~ "(mV)"),
    #     cex = 3.0,
    #     srt = -90)

}



#Set intercept shift if you want to shift the fit line up or down.
tafel.linear_fit <- function(iac.log, potential, range = TRUE, color = 'black',
                             intercept_shift = 0, lwd = 5)
{
    if(is.numeric(range)) {
        x = iac.log[range]
        y = potential[range]
    } else {
        x = iac.log
        y = potential
    }

    fit = lm(y ~ x)
    intercept = fit$coefficients['(Intercept)'] + intercept_shift
    slope = fit$coefficients['x']

    abline(intercept, slope, 
           lwd = lwd, #larger line width
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
