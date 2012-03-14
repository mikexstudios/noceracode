#!/usr/bin/env ruby
require 'erb'
require 'csv'

class FitTable
  attr_accessor :input, :output
  attr_accessor :title, :definition

  def initialize
    template_path = File.join(File.dirname(__FILE__), "fit_template.erb")
    @template = ERB.new(File.read(template_path), 0, trim_mode = '>')
    @title = nil
    @definition = 'lrlllr'
  end

  def make
    #Open the CSV file, get data
    csv = CSV.read(@input)

    definition = @definition
    #The first row is the header
    header = csv.shift
    #The rest is the data
    content = csv
    title = @title

    #Escape the title for any LaTeX sensitive characters
    title.gsub!('%', '\%')
    
    output = File.new(@output, 'w')
    output.puts @template.result(binding)
    output.close
  end
end
def fit_table
  yield FitTable.new
end

if __FILE__ == $0
  ft = FitTable.new
  ft.input = ARGV[0]
  ft.output = ARGV[1]
  ft.title = ''

  ft.make
end
