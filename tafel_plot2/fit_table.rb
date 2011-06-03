require 'erb'
require 'csv'

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

