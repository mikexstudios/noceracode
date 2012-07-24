#Returns a generator function that returns colors with maximum variation.
# num_plots: the total number of plots to generate colors for
# saturation: for the S part in HSV color scheme.
# brightness: for the V part in HSV color scheme.
# TIP: To get the last color, set the last flag to TRUE
varycolor.generator <- function(num_plots = 5, saturation = 1.0, brightness = 0.9) {
    i <- -1
    return(function(last = FALSE) {
        if(last != TRUE) {
            i <<- i + 1
        }
        return(hsv(i/num_plots, saturation, brightness))
    })
}
