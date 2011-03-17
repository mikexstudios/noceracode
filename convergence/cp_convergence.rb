#!/usr/bin/env ruby
#
# Requires: statsample, CSV

if not ARGV.first
  puts 'Usage: %s [cp_file.txt]' % $0
  exit
end

require 'statsample' #for standard deviation
require 'CSV'

# configuration
datafile = ARGV.first
data_start_line = 21 #the line number where data starts
#The final fraction of points to use when computing convergence.
last_fraction_of_points = 0.30
#The fraction we expand around the average that we say is converged.
convergence_fraction = 0.001 #0.1%


#Read in csv file and remove non-CSV header lines
csv = CSV.read(datafile)
csv = csv[(data_start_line-1)..-1]
#Get only the second column of the csv, which is the potential.
col = csv.collect {|i| i.last.to_f}

#Get the last fraction of points and convert to a vector that is defined by
#statssample.
last_num_pts = (col.length * last_fraction_of_points).to_i
last_pts = col[(col.length - last_num_pts)..-1]
last_pts_vec = last_pts.to_vector(:scale) 

#Calculate average of points and determine the convergence expansion.
last_avg = last_pts_vec.sum / last_pts.length
convergence_amt = last_avg * convergence_fraction
puts 'Average: %f' % last_avg
puts 'Convergence Amount: %f' % convergence_amt

#Determine the standard deviation of the last points
last_stdev = last_pts_vec.standard_deviation_population
puts 'Standard Deviation: %f' % last_stdev


#We say that convergence has been reached if the standard deviation is below
#the convergence amount.
if last_stdev <= convergence_amt
  puts 'Converged!'
else
  puts 'NOT converged!'
end
