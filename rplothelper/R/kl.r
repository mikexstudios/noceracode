plot.kl.xlab = ''
plot.kl.ylab = ''
plot.kl.setup <- function() {
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
        lwd = 5, #line width of points
        cex.lab = 3.0, #make axis annotation larger
        cex.axis = 2.9 #make axis label larger
        )
}

plot.kl.is_first_plot = TRUE
plot.kl <- function(...) {
    if (plot.kl.is_first_plot) {
        plot(...,
             axes = FALSE, #we will make our own axes
             ann = FALSE, #we will make our own axes annotation
             type = 'p', #points
             tck = 0, #we will make our own tick marks
             cex = 3.5 #point size
            )
        
        #Setup post-plotting customizations
        box(lwd = 4)

        #Left axis, inner tick mark with tck, thicker line with lwd.
        #axis(2, at = axTicks(2), label = FALSE, lwd = 4, tck = 0.05)
        axis(2, at = axTicks(2), label = TRUE, lwd = 4, tck = 0.05, cex.axis = 2.9)
        mtext(side = 2, text = plot.kl.ylab,
              line = 3.5, cex = 3.0)
        
        #Bottom axis
        axis(1, at = axTicks(1), label = TRUE, lwd = 4, tck = 0.05, cex.axis = 2.9,
             mgp = c(5.6, 1.9, 0))
        mtext(side = 1, text = plot.kl.xlab,
              line = 5.3, cex = 3.0)
        
        minor.tick(nx=2, ny=2, tick.ratio=-2, lwd = 3)

        #Add another axis at the bottom for NHE
        #axis(1, at = axTicks(1), 
        #     label = round(axTicks(1) - potential_reference_correction, digits = 3), 
        #     lwd = 2,
        #     tck = 0.03,
        #     line = 3.3)
        #mtext(1, text = expression(italic('E') * " (V vs. Ag/AgCl)"),
        #      line = 4.8)

        plot.kl.is_first_plot <<- FALSE #need double arrow to overwrite global
    } else {
        points(...,
               cex = 3.5)
    }
}

plot.kl.legend <- function(..., lwd = 6) {
    legend(...,
           cex = 1.9,
           lwd = lwd, 
           seg.len = 5, #longer lines
           bty = 'n')
}



kl.linear_fit <- function(angular_velocity.isq, current.inverse, range = TRUE, 
                          color = 'black', current_rescale_factor = 1, lwd = 6) {
    if(is.numeric(range)) {
        y = current.inverse[range]
        x = angular_velocity.isq[range]
    } else {
        y = current.inverse
        x = angular_velocity.isq
    }

    fit = lm(y ~ x)
    intercept = fit$coefficients['(Intercept)']
    slope = fit$coefficients['x']

    abline(intercept, slope, 
           lwd = lwd, #larger line width
           col = color)

    #Get coefficients and R^2 values
    summ = summary(fit)
    coefficients = summ['coefficients'][[1]]
    slope.stdev = coefficients['x', 'Std. Error']
    rsq = summ['r.squared'][[1]]
    #Let's also put the calculated iac (activation controlled) in the table
    iac = (1/intercept) * current_rescale_factor

    summ = data.frame(slope = slope,
                      slope.stdev = slope.stdev,
                      intercept = intercept,
                      iac = iac,
                      rsq = rsq * 100)
    return(summ)
}

kl.data_dir = ''
kl.sample_rate = NULL
kl.add_rotator_current <- function(rotcurr, filename, skip = 0, average_last = 10) { #in s
    #Extract the rotation speed from the base filename
    angular_velocity = strsplit(filename, '.txt')[[1]]
    angular_velocity = strsplit(angular_velocity, '_')[[1]][3]
    angular_velocity = strsplit(angular_velocity, 'rpm')[[1]]
    angular_velocity = as.numeric(angular_velocity)

    filename = paste(kl.data_dir, filename, sep='') 
    raw_ait_data = read.csv(file = filename, skip = skip, header = TRUE)


    #We start from the last data point and average the last few points (default
    #by the last 10s (divide by the sample rate).
    row_num = nrow(raw_ait_data)
    num_last_pts = average_last / kl.sample_rate
    raw_ait_subset = raw_ait_data[(row_num - num_last_pts):row_num, ]
    current_avg = mean(raw_ait_subset$Current.A)

    #Create new data frame for given information
    new_rotcurr = data.frame(angular_velocity.rpm = angular_velocity,
                             current_ss.A = current_avg)

    #Add new data to existing data frame (if existing frame is empty, will 
    #automatically add correct new columns).
    rotcurr = rbind(rotcurr, new_rotcurr)

    return(rotcurr)
}

kl.simplify_fit_summary <- function(fit_summary) {
    for(i in 1:nrow(fit_summary)) {
        row = fit_summary[i, ]
        row = data.frame(Pot.V = sprintf('%.2f', row$potential), 
                         Pts = row$range,
                         Slope = as.numeric(sprintf('%.2f', row$slope)),
                         Stdev = as.numeric(sprintf('%.2f', row$slope.stdev)),
                         Int = as.numeric(sprintf('%.3f', row$intercept)),
                         iac.A = as.numeric(sprintf('%.2e', row$iac)),
                         Rsq = as.numeric(sprintf('%.2f', row$rsq)) )
        if(i == 1) {
            fit_summary_simplified = row
        } else {
            fit_summary_simplified = rbind(fit_summary_simplified, row)
        }
    }

    return(fit_summary_simplified)
}
