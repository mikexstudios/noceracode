nucleation.data_dir = '' #need to set this globally
nucleation.sample_rate = NULL #need to set this globally
nucleation.add_to_average <- function(all_ait, filename, skip_lines = 0, 
                                      skip_time = 0, bkg_filename = FALSE,
                                      bkg_skip_lines = FALSE) {
    filename = paste(nucleation.data_dir, filename, sep='') 
    ait <- read.csv(file = filename, skip = skip_lines, header = TRUE)

    #If background file has been specified, load it and subtract values from AIT.
    #If lengths are not the same, then take last point of bkg as background.
    if(bkg_filename != FALSE) {
        filename = paste(nucleation.data_dir, bkg_filename, sep='') 
        bkg <- read.csv(file = filename, skip = bkg_skip_lines, header = TRUE)

        #If bkg is shorter than ait
        if(nrow(bkg) < nrow(ait)) {
            #Then, take only the part that we can correct and correct that
            ait_first_part = ait[1:nrow(bkg), ]
            ait_first_part = transform(ait_first_part, 
                                       Current.A = Current.A - bkg$Current.A)

            #Take the last point of bkg and correct the rest
            bkg_last_row = bkg[nrow(bkg), ]
            ait_second_part = ait[nrow(bkg):nrow(ait), ]
            ait_second_part = transform(ait_second_part,
                                        Current.A = Current.A - bkg_last_row$Current.A)

            #Now recombine the rows
            ait = rbind(ait_first_part, ait_second_part)
        } else if (nrow(bkg) == nrow(ait)) {
            #If nrows are equal, simply subtract
            ait = transform(ait, 
                            Current.A = Current.A - bkg$Current.A)
        }
    }
    
    #Skip the specified number of points
    #Typically used when we first apply some kind of lower potential to get rid
    #of double layer charging current. Then we step to the target potential to
    #run the nucleation.
    skip_points = ceiling(skip_time / nucleation.sample_rate) #round up
    ait <- ait[(skip_points + 1):nrow(ait), ] #add 1 because index starts from 1

    #Now normalize all time points by subtracting from the first time point.
    initial_t = ait[1, ]$Time.sec
    ait$Time.sec = ait$Time.sec - initial_t

    #Determine if all_ait has any data in it. If not, when we will completely 
    #overwrite it. Otherwise, we will cbind to it.
    if(length(all_ait) <= 0) {
        all_ait = ait
    } else {
        all_ait[length(all_ait) + 1] = ait$Current.A 
    }

    return(all_ait)
}

nucleation.average_plots <- function(all_ait) {
    #Average all of the columns (from the 2nd column)
    averaged = all_ait[1] #gets the first Time.sec column
    averaged$Current.A = rowMeans(all_ait[, 2:length(all_ait)])

    #Make currents positive
    averaged$Current.A = abs(averaged$Current.A)

    return(averaged)
}


nucleation.linear_fit <- function(x, y, range = TRUE, color = 'black',
                             intercept_shift = 0, lwd = 5) {
    if(is.numeric(range)) {
        x = x[range]
        y = y[range]
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
