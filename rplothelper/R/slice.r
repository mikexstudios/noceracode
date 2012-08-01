plot.slice.xlab = ''
plot.slice.ylab = ''
plot.slice.setup <- function() {
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

plot.slice.is_first_plot = TRUE
plot.slice <- function(..., cex = 5.0) {
    if (plot.slice.is_first_plot) {
        plot(...,
             axes = FALSE, #we will make our own axes
             ann = FALSE, #we will make our own axes annotation
             type = 'p', #points
             tck = 0, #we will make our own tick marks
             cex = cex #point size
            )
        
        #Setup post-plotting customizations
        box(lwd = 4)

        #Left axis, inner tick mark with tck, thicker line with lwd.
        #axis(2, at = axTicks(2), label = FALSE, lwd = 4, tck = 0.05)
        axis(2, at = axTicks(2), label = TRUE, lwd = 4, tck = 0.05, cex.axis = 2.9)
        mtext(side = 2, text = plot.slice.ylab,
              line = 3.5, cex = 3.0)
        
        #Bottom axis
        axis(1, at = axTicks(1), label = TRUE, lwd = 4, tck = 0.05, cex.axis = 2.9,
             mgp = c(5.6, 1.9, 0))
        mtext(side = 1, text = plot.slice.xlab,
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

        plot.slice.is_first_plot <<- FALSE #need double arrow to overwrite global
    } else {
        points(...,
               cex = cex)
    }
}

plot.slice.legend <- function(..., lwd = 6, cex = 2.0, seg.len = 3) {
    legend(...,
           cex = cex,
           lwd = lwd, 
           seg.len = seg.len, #longer lines
           bty = 'n')
}


#is_piece - if TRUE, uses abline.piece to plot fit lines, which do not extend
#           throughout the whole plot.
#clip_extend - defines the extra extension of abline.piece 
slice.linear_fit <- function(concentration.log, current.log, range = TRUE, 
                             color = 'black', is_piece = TRUE, clip_extend = 0.05,
                             lwd = 8) {
    if(is.numeric(range)) {
        x = concentration.log[range]
        y = current.log[range]
    } else {
        x = concentration.log
        y = current.log
    }

    fit = lm(y ~ x)
    intercept = fit$coefficients['(Intercept)']
    slope = fit$coefficients['x']

    if (is_piece && range != TRUE) {
        abline.piece(intercept, slope, 
               lwd = lwd, #larger line width
               col = color,
               #We then get the from and to values from specified range
               from = concentration.log[head(range, n=1)] - clip_extend,
               to = concentration.log[tail(range, n=1)] + clip_extend)
    } else {
        abline(intercept, slope, 
               lwd = lwd, #larger line width
               col = color)
    }

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


slice.hslice_tafels <- function(filenames, concentrations, potential) {
    result = data.frame()
    #There seems to be a bug in R in that the potential, seemingly
    #randomly, loses precision or something. So this is a crude fix:
    potential = as.numeric(as.character(potential))

    #For each file, iterate through it
    for(i in 1:length(filenames)) {
        filename = filenames[i]
        concentration = concentrations[i]

        #Open each file as CSV, headers are included
        tafel = read.csv(file = filename, header = TRUE)

        #Get the current for given potential
        row = tafel[tafel$potential == potential, ]
        if(nrow(row) != 1) next

        #Make a new data frame with relevant information
        df = data.frame(concentration = concentration,
                        current = row$iac)

        #Add row to our data frame
        result = rbind(result, df)
    }

    return(result)
}


slice.surface_area = NULL #need to set this for vslice_tafel
slice.vslice_tafels <- function(filenames, pHs, logcurrent, low_fit_ranges) {
    result = data.frame()

    #For each file, iterate through it
    for(i in 1:length(filenames)) {
        filename = filenames[i]
        pH = pHs[i]
        low_fit_range = low_fit_ranges[i]
        low_fit_range = as.numeric(strsplit(low_fit_range, ':')[[1]][1]):as.numeric(strsplit(low_fit_range, ':')[[1]][2])

        #Open each file as CSV, headers are included
        tafel = read.csv(file = filename, header = TRUE)
        #Normalize the current to 1cm^2
        tafel$iac_norm = tafel$iac / slice.surface_area
        #Take log of current
        tafel$iac.log = log10(tafel$iac_norm)


        #Get the potential for a given logcurrent. We estimate
        #this value from the linear fit line.
        summ = slice.calc_linear_fit_tafel(tafel, range = low_fit_range)
        #y = m*x + b
        potential = summ$slope * logcurrent + summ$intercept

        #Make a new data frame with relevant information
        df = data.frame(pH = pH,
                        potential = potential)

        #Add row to our data frame
        result = rbind(result, df)
    }

    return(result)
}

slice.calc_linear_fit_tafel <- function(tafel, range = TRUE) {
    #NOTE: iac.log has already been normalized!
    if(is.numeric(range)) {
        x = tafel$iac.log[range]
        y = tafel$potential[range]
    } else {
        x = tafel$iac.log
        y = tafel$potential
    }

    fit = lm(y ~ x)
    intercept = fit$coefficients['(Intercept)']
    slope = fit$coefficients['x']

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
