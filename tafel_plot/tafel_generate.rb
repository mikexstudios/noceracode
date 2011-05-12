#!/usr/bin/env ruby
# Requires: micro-optparse (http://florianpilz.github.com/micro-optparse/)

require 'micro-optparse'

options = Parser.new do |p|
  p.banner = <<-eos
    Given a set of CP or AIT experiments, pulls out the final point into a
    Tafel csv.
  eos
  p.option :filename_format, 'filename format, use %d to indicate data point placeholder', :default => 'cp%d_1.txt'
  p.option :data_type, 'input data file, cp (default) or ait', :default => 'cp', :short => 't'
  p.option :uncompensated_resistance, 'uncompensated resistance in ohms', :default => 0.0
  p.option :data_start, 'starting data point, inserted in place of \%d', :default => 1, :short => 's'
  p.option :data_end, 'ending data point, inserted in place of \%d', :default => 13, :short => 'e'
end.process!

# configuration
datafiles = options[:filename_format]
data_type = options[:data_type]
data_start = options[:data_start].to_i
data_end = options[:data_end].to_i
uncompensated_resistance = options[:uncompensated_resistance].to_f #ohms

for i in data_start..data_end do
  file = datafiles % i #generate filename of the current file.

  f = File.open(file)
  f.each do |line|
    #Depending on the file type, we look for different information.
    case data_type
    when 'cp'
      #Look for the anodic current line
      #ie. Anodic Current (A) = 1e-7
      if line =~ /Anodic Current \(A\) = ([\d.e-]+)\s*/
          $current = $1.to_f
          break
      end
    when 'ait'
      #Look for potential line
      if line =~ /Init E \(V\) = ([\d.e-]+)\s*/
          $potential = $1.to_f
          break
      end
    else
      abort('data_type parameter is invalid')
    end
  end
  f.close

  #Get the last line of the file (which we are assuming is where equilibrium 
  #occurs).
  cmd = 'tail -n1 %s' % file
  last_pt = `#{cmd}`
  #puts last_pt

  case data_type
  when 'cp'
    $potential = last_pt.split(',').last.strip()
    #Convert from scientific string to floating pt number.
    $potential = $potential.to_f 
  when 'ait'
    $current = last_pt.split(',').last.strip()
    #Convert from scientific string to floating pt number.
    $current = $current.to_f 
    #If we have a negative current, then make it positive (the negative sign is
    #just a formality for signifying anodic current).
    $current = -1.0 * $current if $current < 0
  else
    abort('data_type parameter is invalid')
  end

  #Since we want a Tafel plot, take the log of the current:
  $logcurrent = Math.log10($current)

  #iR correction on the potential. We subtract i*R_u from the potential.
  $potential = $potential - $current * uncompensated_resistance
  #puts 'Comp: %e ' % ($current * uncompensated_resistance)
      
  puts '%e, %e' % [$logcurrent, $potential]
end
