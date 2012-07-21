## Copyright (C) 2001 Frank E Harrell Jr
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by the
## Free Software Foundation; either version 2, or (at your option) any
## later version.
##
## These functions are distributed in the hope that they will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## The text of the GNU General Public License, version 2, is available
## as http://www.gnu.org/copyleft or by writing to the Free Software
## Foundation, 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
##
minor.tick <- function(nx=2, ny=2, tick.ratio=.5, ...)
{
  ax <- function(w, n, tick.ratio)
  {
    range <- par("usr")[if(w=="x") 1:2
                        else 3:4]
    
    tick.pos <-
      if(w=="x")
        par("xaxp")
      else par("yaxp")

    ## Solve for first and last minor tick mark positions that are on the graph

    distance.between.minor <- (tick.pos[2]-tick.pos[1])/tick.pos[3]/n
    possible.minors <- tick.pos[1]-(0:100)*distance.between.minor  #1:100 13may02
    low.minor <- min(possible.minors[possible.minors>=range[1]])
    if(is.na(low.minor)) low.minor <- tick.pos[1]
    possible.minors <- tick.pos[2]+(0:100)*distance.between.minor  #1:100 13may02
    hi.minor <- max(possible.minors[possible.minors<=range[2]])
    if(is.na(hi.minor))
      hi.minor <- tick.pos[2]

    #if(.R.)
      #TODO: Implement: https://stat.ethz.ch/pipermail/r-help/2008-July/167434.html
      #If values passed in ... are variables.
      axis(if(w=="x") 1
           else 2,
           seq(low.minor,hi.minor,by=distance.between.minor),
           labels=FALSE, tcl=par('tcl')*tick.ratio, ...)
    #else
    #  axis(if(w=="x") 1
    #       else 2,
    #       seq(low.minor,hi.minor,by=distance.between.minor),
    #       labels=FALSE, tck=par('tck')*tick.ratio)
  }

  if(nx>1)
    ax("x", nx, tick.ratio=tick.ratio)
  
  if(ny>1)
    ax("y", ny, tick.ratio=tick.ratio)

  invisible()
}
