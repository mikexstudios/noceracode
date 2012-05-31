#!/usr/bin/env ruby

require 'CSV'

class CVParser
  attr_accessor :data

  def initialize(path)
    @cv_path = path
    @segments = [] #stores array of CV segments; calculated from @data

    @init_e = nil
    @high_e = nil #we will double check these from the actual data
    @low_e = nil
    @high_i = nil #we will double check these from the actual data
    @low_i = nil
  end

  def parse
    is_in_data = false #state flag which keeps track of if we hit the data
                       #section of the CV file yet.
    f = File.open(@cv_path)
    f.each do |line|
      if    line.start_with? 'Init E'
        @init_e = line.split('=').last.to_f
      elsif line.start_with? 'High E'
        #@high_e = line.split('=').last.to_f
        nil
      elsif line.start_with? 'Low E'
        #@low_e = line.split('=').last.to_f
        nil
      elsif line.start_with? 'Segment'
        nil
      elsif line.start_with? 'Potential/V, Current/A'
        is_in_data = true
        break
      else
        next
      end

      if is_in_data == true
        break
      end
    end

    #Now that we are in the data section, we need to parse each Segment
    #delimiter.
    f.each do |line|
      if line.start_with? 'Segment'
        #For this until next segment, parse into CSV
        @segments.push parse_segment_csv(f)
      else
        next
      end
    end

    f.close
  end

  def get_segment(range = 0..-1) #default to full range
    #If range is specified as an integer instead of a range, make it a range
    #such that the return slice is wrapped in an array, for consistentcy 
    #purposes.
    #ie. [1, 2, 3, 4].slice(1) => 2
    #    [1, 2, 3, 4].slice(1..1) => [2]
    range = Range.new(range, range) if range.is_a? Integer

    return @segments.slice(range)
  end

  def get_segment_as_csv(range = 0..-1) #default: full range
    data = get_segment(range)

    data.unshift([['potential', 'current']]) #CSV header

    return data.map do |segment| #we may have multiple returned segments
      segment.map { |point| point.to_csv }.join
    end.join #join array elements to string
    #end.join("\n") #join array elements to string
  end


  private
   
  # Given an open file in which the current line is the start of segment data,
  # parses each line as CSV and returns an array of data points.
  def parse_segment_csv(f)
    data = []
    f.each do |line|
      break if line.strip.empty? #end of segment when blank line encountered
      data.push CSV.parse(line).first
    end

    return data
  end

end

#Ability to run the script standalone if not required/included.
if __FILE__ == $0
  if not ARGV[0]
    puts 'Usage: %s [cv_data.txt] {segment range}' % $0
    puts 'NOTE: {segment range} is specified as integer or Ruby range'
    puts '      and begins at 0. For example: 2, 2..3, 0..-2.'
    exit
  end
  
  cv_path = ARGV[0]
  segment_range = ARGV[1]
  #We have three cases for the supplied segment range.
  if not segment_range.nil?
    #1. Just one segment
    if segment_range.index('..') #we find a range specification
      r = segment_range.split('..').map {|s| s.to_i}
      segment_range = Range.new(*r)
    else
      #2. Assume single integer
      segment_range = segment_range.to_i
    end
  else
    #3. No range specified
    segment_range = 0..-1 #full range
  end

  
  cv = CVParser.new(cv_path)
  cv.parse
  puts cv.get_segment_as_csv segment_range
end
