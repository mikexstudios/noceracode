require 'CSV'

class CVParser
  attr_accessor :data

  def initialize(path)
    @cv_path = path
    @data = nil #stores the array of CSV data
    #Flag which is true when the potential and current ranges have been
    #calculated.
    @is_potential_current_range_calcuated = false

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

    #We skip blanks because they are unnecessary. We use the float converter
    #to automatically parse all the string input into float numerals.
    c = CSV.new(f, { :skip_blanks => true, :converters => :float })

    #We assume that no CV is so monstrous that it can't be fit into modern day
    #RAM, lol. Thus, let's just stuff everything in memory.
    @data = c.readlines

    f.close
  end

  def get_potential_range
    calculate_potential_current_ranges
    
    return [@low_e, @high_e]
  end

  def get_current_range
    calculate_potential_current_ranges

    return [@low_i, @high_i]
  end

  def get_segment(range)
  end

  private

  def calculate_potential_current_ranges
    return if @is_potential_current_range_calcuated == true

    #First, populate the @low_e and @high_e with initial values (taken from the
    #first entry in the @data array).
    @low_e = @data.first.first
    @high_e = @data.first.first
    #Same for current
    @low_i = @data.first.last
    @high_i = @data.first.last

    @data.each do |point|
      e = point.first
      i = point.last
      @low_e  = e if e < @low_e
      @high_e = e if e > @low_e
      @low_i  = i if i < @low_i
      @high_i = i if i > @low_i
    end

    @is_potential_current_range_calcuated = true
  end

end

cv = CVParser.new('cv9 05mm mn 50mm kbi ph9 10mvs.txt')
cv.parse
p cv.data
p cv.get_potential_range
p cv.get_current_range
