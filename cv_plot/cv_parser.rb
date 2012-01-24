require 'CSV'

class CVParser
  attr_accessor :data

  def initialize(path)
    @cv_path = path
    @data = nil #stores the array of CSV data
    @segments = [] #stores array of CV segments; calculated from @data
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
    segment_data

    return @segments
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

  def segment_data
    return if not @segments.empty?

    #Algorithm:
    #1. Always compute differences between potential values.
    #2. Assign that difference to a positive or negative direction.
    #3. Once we change direction, that's when we segment the data.
    
    #We keep track of the last point so that we can take the difference.
    last_point = nil
    last_direction = nil
    last_segment_i = 0 #index of @data where last segment stopped

    @data.each_with_index do |point, current_i|
      if last_point.nil?
        last_point = point
        next
      end

      current_direction = determine_direction_of_scan(last_point, point) 
      if current_direction != last_direction and current_direction != 0 \
        and not last_direction.nil?
        #Segment the data at this point. We slice to current_i - 1 since 
        #the current_i is where the change happened; we want to end at
        #the previous point.
        @segments.push(@data.slice(last_segment_i..(current_i-1)))

        last_segment_i = current_i
      end

      last_point = point
      last_direction = current_direction
    end

    #Take care of the last segment that did not change direction (because it
    #was the last segment).
    @segments.push(@data.slice(last_segment_i..-1))
  end

  def determine_direction_of_scan(point1, point2)
    #If either point is nil, let's say that we don't change directions 
    #(ie. return 0). We only get nil points when we start at the first data
    #point anyway (because there is no last_point).
    #return 0 if point1.nil? or point2.nil? #no direction

    last_e = point1.first
    current_e = point2.first

    diff = current_e - last_e
    return  1 if diff > 0 #positive direction
    return -1 if diff < 0 #negative direction
    return  0             #no direction
  end

end

cv = CVParser.new('cv9 05mm mn 50mm kbi ph9 10mvs.txt')
cv.parse
p cv.data
p cv.get_potential_range
p cv.get_current_range
s = cv.get_segment nil
puts s.length
p s
