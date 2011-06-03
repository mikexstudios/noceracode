require 'rsruby'

class TafelPlot
  attr_accessor :input, :output, :title, :color, :fit_match_color

  def initialize
    @r = RSRuby.instance
    @title = ''
    @x_label = 'log(i / A/cm^2)'
    @y_label = 'E / V (vs Ag/AgCl)'
    @color = 'black'
    @fit_color = 'red'
    #If set to true, the fit color will match the plot color.
    @fit_match_color = false

    #For multiple plots, we need to keep track if we already used the `plot`
    #command. If so, the subsequent plots are drawn with `points`.
    @already_drawn = false
  end

  def points
  end

  # Adds a linear fit to the plot and reports the linear parameters.
  # If no range of points is specified, the fit will be over all points.
  # NOTE: range should be specified using ruby range, ie. 3..5
  # If draw is false, then line will not be plotted, but fitting parameters
  # will be shown.
  def linear_fit(range = nil, draw = true)
    raise "Need to call 'draw' first before fitting!" if not defined? @x

    #If range is specified process it.
    if range and range != 'all'
      x = @x.slice(range)
      y = @y.slice(range)
    else
      x = @x
      y = @y
    end

    #See: http://goo.gl/lAsEB for example using rsruby to fit line.
    #rsruby is not very advanced, so need to manually assign in the variables
    @r.assign('x', x)
    @r.assign('y', y)

    #fit = @r.lm('y ~ x') #linear model of y = m*x + b
    #We use the below instead of above to assign the output to fit and get the
    #fit object all at once.
    fit = @r.eval_R("fit <- lm('y ~ x')")
    coefficients = fit['coefficients']
    coefficients = { :slope => coefficients['x'], 
                     :intercept => coefficients['(Intercept)'] }

    #Since color and other such parameters can be specified anywhere in R, we 
    #need to mirror that by attaching a hash at the end.
    if draw
      @r.abline(coefficients[:intercept], coefficients[:slope], 
                { :col => @fit_match_color ? @color : @fit_color  })
    end

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
    puts 'NOT DRAWN' if not draw
    puts 'For file:  %s' % @input
    puts 'For range: %s' % range if range
    puts 'Slope:     %6.2f mV +/- %6.2f mV' % [coefficients[:slope][:estimate] * 1000, 
                                   coefficients[:slope][:std_error] * 1000]
    puts 'Intercept: %6.2f  V +/- %6.2f  V' % [coefficients[:intercept][:estimate],
                                   coefficients[:intercept][:std_error]]
    puts 'R^2:       %6.2f' % [r_squared * 100]
    puts
  end

  def draw
    t = @r.read_csv(file = @input, header = false)
    @x = t['V1'] #for convenience
    @y = t['V2']
    #If this is our second plot, we need to add the points using `points` and
    #not plot.
    if not @already_drawn
      @r.plot(@x, @y, plot_arguments)
      @already_drawn = true
    else
      @r.points(@x, @y, plot_arguments)
    end

    puts '-----------------------------------------'
    puts
  end

  def save
    @r.dev_off.call #need .call or else we are just accessing the dev_off obj.
  end

  def output=(filename)
    @output = filename
    #Open up new file for plotting
    @r.pdf(@output)
  end

  private

  # Check for set class variables and then return a hash of arguments
  def plot_arguments
    args = {}
    if not @already_drawn
      args[:main] = @title if not @title.empty?
      #Always include x and y axes labels
      args[:xlab] = @x_label
      args[:ylab] = @y_label
    end
    args[:col] = @color

    return args
  end

end
def tafel_plot
  yield TafelPlot.new
end
