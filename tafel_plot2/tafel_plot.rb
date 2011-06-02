#!/usr/bin/env ruby
require 'ruby-debug'

require './tafel_extractor' #for cp_to_tafel

# Example session for plotting

$uncompensated_resistance = 21.7 #ohms
$plot_title = '5 layer Mn in 0.5 M KPi, pH 2.49; H->L, 300s/pt - Pass #{pass} (04/02/2011)'
$pass_colors = ['red', 'orange', 'cadetblue1', 'green', 'blue', 'purple', 'black']
$combined_ylim = [0.58, 1.03]

# Convert sets of CP files to tafel data
cp_to_tafel do |convert|
  break #skip generation
  convert.uncompensated_resistance = $uncompensated_resistance
  convert.process 'cp*_1.txt', 'tafel_1.csv'
  convert.process 'cp*_2.txt', 'tafel_2.csv'
  convert.process 'cp*_3.txt', 'tafel_3.csv'
  convert.process 'cp*_4.txt', 'tafel_4.csv'
  convert.process 'cp*_5.txt', 'tafel_5.csv'
  convert.process 'cp*_6.txt', 'tafel_6.csv'
end


class TafelPlot
  attr_accessor :input, :output, :title, :color

  def initialize
  end

  def points
  end

  def linear_fit
  end

  def draw
    #Get input filename without extension
    name = File.basename(@input, '.*')

    #Open up Rscript file for output
    r = File.new('%s.R' % name, 'w')
    r.puts '#!/usr/bin/env Rscript'

    r.puts "pdf('%s')" % @output
    r.puts "t <- read.csv(file='%s', header = FALSE)" % @input
    r.puts <<-PLOT
    plot(t$V1, t$V2, 
         main="#{@title}", 
         xlab="#{@x_title}", 
         ylab="#{@y_title}")
    PLOT

    r.close

    #Execute the script
    `Rscript #{name}`
    #`open #{@output}`
  end

end
def tafel_plot
  yield TafelPlot.new
end

# Create single plot
tafel_plot do |plot|
  plot.input = 'tafel_1.csv'
  plot.output = 'tafel_1.pdf'
  plot.title = $plot_title
  #plot.points [3, 5], 6, [8-13]
  plot.linear_fit #can optionally specify pt range
  plot.draw
end

exit

# Create multiple plots
tafel_plot do |plot|
  plot.title = $plot_title

  plot.input = 'tafel_1.csv'
  plot.output = 'tafel_1.pdf'
  plot.pts [3, 5], 6, [8-13]
  plot.linear_fit #can optionally specify pt range
  plot.draw

  plot.input 'tafel_2.csv'
  plot.output = 'tafel_2.pdf'
  plot.pts [3, 5], 6, [8-13]
  plot.linear_fit #can optionally specify pt range
  plot.draw
end
