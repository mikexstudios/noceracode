#!/usr/bin/env ruby
require 'ruby-debug'
require 'rsruby'

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
    @r = RSRuby.instance
    @title = ''
    @x_label = 'log(i / A/cm^2)'
    @y_label = 'E / V (vs Ag/AgCl)'
    @fit_color = 'red'
  end

  def points
  end

  def linear_fit
    raise "Need to call 'draw' first before fitting!" if not defined? @x

    #See: http://goo.gl/lAsEB for example using rsruby to fit line.
    #rsruby is not very advanced, so need to manually assign in the variables
    @r.assign('x', @x)
    @r.assign('y', @y)

    #fit = @r.lm('y ~ x') #linear model of y = m*x + b
    #We use the below instead of above to assign the output to fit and get the
    #fit object all at once.
    fit = @r.eval_R("fit <- lm('y ~ x')")
    coefficients = fit['coefficients']
    coefficients = { :slope => coefficients['x'], 
                     :intercept => coefficients['(Intercept)'] }

    #Since color and other such parameters can be specified anywhere in R, we 
    #need to mirror that by attaching a hash at the end.
    @r.abline(coefficients[:intercept], coefficients[:slope], 
              { :col => @fit_color })

    #Also print formatted output of coefficients and R^2 values
    summary = @r.eval_R('summary(fit)')

    #Transform the glob of mess that we get back into something more meaningful
    r_squared = summary['r.squared']

    coefficients = summary['coefficients']
    coefficients = { :slope => coefficients.last, 
                     :intercept => coefficients.first }
    temp = {}
    coefficients.keys.each do |key|
      temp[key] = {
        :estimate => coefficients[key][0],
        :std_error => coefficients[key][1],
        :t_value => coefficients[key][2],
        :pr => coefficients[key][3],
      }
    end
    coefficients = temp

    #Now out the values
    puts 'Slope:     %6.2f mV +/- %6.2f mV' % [coefficients[:slope][:estimate] * 1000, 
                                   coefficients[:slope][:std_error] * 1000]
    puts 'Intercept: %6.2f  V +/- %6.2f  V' % [coefficients[:intercept][:estimate],
                                   coefficients[:intercept][:std_error]]
    puts 'R^2:       %6.2f' % [r_squared * 100]
    puts


  end

  def draw
    @r.pdf(@output)
    t = @r.read_csv(file = @input, header = false)
    @x = t['V1'] #for convenience
    @y = t['V2']
    @r.plot(@x, @y, plot_arguments)
  end

  def save
    @r.dev_off.call #need .call or else we are just accessing the dev_off obj.
  end

  private

  # Check for set class variables and then return a hash of arguments
  def plot_arguments
    args = {}
    args[:main] = @title if not @title.empty?
    #Always include x and y axes labels
    args[:xlab] = @x_label
    args[:ylab] = @y_label

    return args
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
  plot.draw
  plot.linear_fit #can optionally specify pt range
  plot.save
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
