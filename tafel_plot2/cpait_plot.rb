require 'rubygems'
require 'rsruby'
#require 'ruby-debug'

class CPAITPlot
  attr_accessor :input, :output
  attr_accessor :x_range, :y_range
  attr_accessor :x_label, :y_label

  def initialize
    @r = RSRuby.instance
    @title = ''
    @x_label = 't (s)'
    @y_label = 'E / V (vs Ag/AgCl)'
    #@color = 'black'

    @rows_cols = [3, 3]
  end

  def draw
    #Get list of files from the input glob. We assume they are in the correct
    #order by filename. Even if the input is a single file, this loop will only
    #run once.
    Dir[@input].each do |filename|
      t = @r.read_csv(file = filename, header = false)
      @x = t['V1'] #for convenience
      @y = t['V2']
      @title = filename
      
      @r.plot(@x, @y, plot_arguments)
    end
  end

  def save
    @r.dev_off.call #need .call or else we are just accessing the dev_off obj.

    @output_fit_csv.close if @output_fit_csv
  end


  def output=(filename)
    @output = filename
    #Open up new file for plotting
    @r.pdf(@output)
  end

  def rows_cols=(dim)
    @rows_cols = dim

    #Set R par grid
    @r.par(:mfrow => dim) #row, col
  end


  private

  # Check for set class variables and then return a hash of arguments
  def plot_arguments
    args = {}
    args[:main] = @title if not @title.empty?
    #Always include x and y axes labels
    args[:xlab] = @x_label
    args[:ylab] = @y_label
    
    args[:xlim] = @x_range if @x_range
    args[:ylim] = @y_range if @y_range
    args[:col] = @color if @color

    #cex controls the point size
    args[:cex] = @cex ? @cex : 0.4

    return args
  end

end
def cp_plot
  yield CPAITPlot.new
end
def ait_plot
  yield CPAITPlot.new
end
