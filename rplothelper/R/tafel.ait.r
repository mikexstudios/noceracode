tafel.ait.data_dir = ''
tafel.ait.sample_rate = 1

#Note, skip to the line right before where the parameters are specified
#(ie. Init E (V), etc.)
tafel.ait.get_potential <- function(filename, skip = 9) {
    filename = paste(tafel.ait.data_dir, filename, sep='') 
    params = read.table(file = filename, 
                        sep = '=', 
                        skip = 9, 
                        header = FALSE, 
                        nrow = 6, 
                        strip.white = TRUE, 
                        col.names = c('key', 'value'))

    return(params[params$key == 'Init E (V)', 'value'])
}

tafel.ait.get_current <- function(filename, skip = 16, average_last = 10, #in s
                                make_positive = TRUE) {
    ##Extract the rotation speed from the base filename
    #angular_velocity = strsplit(filename, '.txt')[[1]]
    #angular_velocity = strsplit(angular_velocity, '_')[[1]][3]
    #angular_velocity = strsplit(angular_velocity, 'rpm')[[1]]
    #angular_velocity = as.numeric(angular_velocity)

    filename = paste(tafel.ait.data_dir, filename, sep='') 
    raw_ait_data = read.csv(file = filename, skip = skip, header = TRUE)

    #We start from the last data point and average the last few points (default
    #by the last 10s (divide by the sample rate).
    row_num = nrow(raw_ait_data)
    num_last_pts = average_last / tafel.ait.sample_rate
    raw_ait_subset = raw_ait_data[(row_num - num_last_pts):row_num, ]
    current_avg = mean(raw_ait_subset$Current.A)

    #Make the current positive (since negative currents are simply by
    #convention)
    if(make_positive && current_avg < 0) {
        current_avg = -1 * current_avg
    }

    return(current_avg)
}

tafel.ait.add <- function(tafel, filename, average_last = 10) {
    potential = tafel.ait.get_potential(filename)
    current = tafel.ait.get_current(filename, average_last = average_last)
    df = data.frame(potential = potential,
                    current = current)
    return(rbind(tafel, df))
}
