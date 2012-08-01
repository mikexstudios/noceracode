#From Remko Duursma (remkoduursma at gmail.com)
#https://stat.ethz.ch/pipermail/r-help/2009-January/185698.html
#Enables finite segment length for abline.
abline.piece <- function(a = NULL, b = NULL, reg = NULL, from, to, ...){ 

    # Borrowed from abline 
    if (!is.null(reg)) a <- reg 

    if (!is.null(a) && is.list(a)) { 
            temp <- as.vector(coefficients(a)) 

        if (length(temp) == 1) { 
            a <- 0 
            b <- temp 
        } 
        else { 
            a <- temp[1] 
            b <- temp[2] 
        } 
    } 

    segments(x0 = from, x1 = to, 
             y0 = a + from * b, y1 = a + to * b,
             ...) 
} 
