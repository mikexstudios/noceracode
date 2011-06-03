#!/usr/bin/env ruby
require 'ruby-debug'

require './tafel_extractor' #for cp_to_tafel
require './tafel_plot' #for tafel_plot

# Example session for plotting

$uncompensated_resistance = 21.7 #ohms
$plot_title = '5 layer Mn in 1 M KBi, pH 9.22; L-H, 300s/pt (05/30/2011)'
$pass_colors = ['red', 'orange', 'cadetblue1', 'green', 'blue', 'purple', 'black']
#$combined_ylim = [0.58, 1.03]

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

# Create single plot
tafel_plot do |plot|
  break
  pass = 6
  plot.input = 'tafel_%i.csv' % pass
  plot.output = 'tafel_%i.pdf' % pass
  plot.draw
  #plot.linear_fit #can optionally specify pt range

  plot.save

  `open tafel_#{pass}.pdf`
end


# Create multiple plots
tafel_plot do |plot|
  pass = 0 #for legend title

  plot.title = $plot_title
  plot.fit_match_color = true
  plot.output = 'tafel_combined.pdf'
  plot.y_range = [0.89, 1.07] #V
  plot.output_fit_csv = 'tafel_combined_fit.csv'

  plot.input = 'tafel_1.csv'
  plot.legend_title = 'Pass %i' % pass += 1
  plot.color = $pass_colors.shift
  plot.draw
  plot.linear_fit 1..6
  plot.linear_fit 6..10, draw = false
  plot.linear_fit 9..13

  plot.input = 'tafel_2.csv'
  plot.legend_title = 'Pass %i' % pass += 1
  plot.color = $pass_colors.shift
  plot.draw
  plot.linear_fit 2..9
  plot.linear_fit 9..13

  plot.input = 'tafel_3.csv'
  plot.legend_title = 'Pass %i' % pass += 1
  plot.color = $pass_colors.shift
  plot.draw
  plot.linear_fit 4..10

  plot.input = 'tafel_4.csv'
  plot.legend_title = 'Pass %i' % pass += 1
  plot.color = $pass_colors.shift
  plot.draw
  plot.linear_fit 3..9
  plot.linear_fit 9..13

  plot.input = 'tafel_5.csv'
  plot.legend_title = 'Pass %i' % pass += 1
  plot.color = $pass_colors.shift
  plot.draw
  plot.linear_fit 2..9
  plot.linear_fit 9..13

  plot.input = 'tafel_6.csv'
  plot.legend_title = 'Pass %i' % pass += 1
  plot.color = $pass_colors.shift
  plot.draw
  plot.linear_fit 1..9
  plot.linear_fit 10..13

  plot.show_legend
  plot.save

  `open tafel_combined.pdf`
end

require 'erb'
require 'csv'
require 'ruby-debug'
class FitTable
  attr_accessor :input, :output
  attr_accessor :title

  def initialize
    @template = ERB.new(File.read('fit_template.erb'), 0, trim_mode = '>')
    @title = nil
  end

  def make
    #Open the CSV file, get data
    csv = CSV.read(@input)

    #The first row is the header
    header = csv.shift
    #The rest is the data
    content = csv
    title = @title
    
    output = File.new(@output, 'w')
    output.puts @template.result(binding)
    output.close
  end
end
def fit_table
  yield FitTable.new
end

fit_table do |table|
  table.input = 'tafel_combined_fit.csv'
  table.output = 'tafel_combined_fit.tex'
  table.title = $plot_title
  table.make

  `pdflatex #{table.output}`
  name = File.basename(table.output, '.*')
  pdf = '%s.pdf' % name
  `open #{pdf}`
end
