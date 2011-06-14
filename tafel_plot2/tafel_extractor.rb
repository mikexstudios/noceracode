class TafelExtractor
  attr_accessor :type, :uncompensated_resistance

  def initialize(type = 'cp')
    @type = type
  end

  def process(input_file, output_file)
    @uncompensated_resistance = @uncompensated_resistance.to_f

    output = File.new(output_file, 'w')
    #Get list of files from the input_file glob. We assume they are in the
    #correct order by filename.
    Dir[input_file].each do |filename|
      case @type
      when 'cp'
        current = cp_current_line(filename)
        potential = converged_pt(filename)
      when 'ait'
        potential = ait_potential_line(filename)
        current = converged_pt(filename)
        #If we have a negative current, then make it positive (the negative
        #sign is just a formality for signifying anodic current).
        current = -1.0 * current if current < 0
      else
        raise "Invalid data type (only accept 'cp' or 'ait')"
      end

      #Since we want a Tafel plot, take the log of the current:
      logcurrent = Math.log10(current)

      #iR correction on the potential. We subtract i*R_u from the potential.
      potential = potential - current * uncompensated_resistance

          
      #Put out scientifically
      output.puts '%e, %e' % [logcurrent, potential]
    end #Dir
    output.close
  end

  private

  # Given a filename, returns the converged data point. For now, we simply 
  # return the final, last point of the file.
  def converged_pt(filename)
    cmd = 'tail -n1 %s' % filename
    last_pt = `#{cmd}`
    return last_pt.split(',').last.strip().to_f
  end

  def cp_current_line(filename)
    f = File.open(filename)
    f.each do |line|
      #Look for the anodic current line
      #ie. Anodic Current (A) = 1e-7
      #TODO: Make more general for cathodic currents too
      if line =~ /Anodic Current \(A\) = ([\d.e-]+)\s*/
          current = $1.to_f
          return current
      end
    end
    f.close

    raise 'Current line not found in file!'
  end

  def ait_potential_line(filename)
    f = File.open(filename)
    f.each do |line|
      #Look for potential line
      if line =~ /Init E \(V\) = ([\d.e-]+)\s*/
          potential = $1.to_f
          return potential
      end
    end
    f.close

    raise 'Potential line not found in file!'
  end

end

def cp_to_tafel
  yield TafelExtractor.new('cp')
end
def ait_to_tafel
  yield TafelExtractor.new('ait')
end
