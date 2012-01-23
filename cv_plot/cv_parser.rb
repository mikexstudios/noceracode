require 'CSV'

class CVParser
  #attr_accessor :type, :uncompensated_resistance

  def initialize(path)
    @cv_path = path
    @csv_f = File.open(@cv_path)

    #If set to true, bypasses checking start of line and jumps directly into
    #CSV parsing.
    @in_data = false
  end

  def parse
    @csv_f.each do |line|
      if    line.start_with? 'Init E'
        nil
      elsif line.start_with? 'High E'
        nil
      elsif line.start_with? 'Low E'
        nil
      elsif line.start_with? 'Segment'
        nil
      elsif line.start_with? 'Potential/V, Current/A'
        @in_data = true
        break
      else
        next
      end

      if @in_data == true
        break
      end
    end

    #We skip blanks because they are unnecessary. We use the float converter
    #to automatically parse all the string input into float numerals.
    c = CSV.new(@csv_f, { :skip_blanks => true, :converters => :float })
    p c.readlines
  end

end

cv = CVParser.new('cv9 05mm mn 50mm kbi ph9 10mvs.txt')
cv.parse
