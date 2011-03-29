#!/usr/bin/env ruby
# Requires: micro-optparse (http://florianpilz.github.com/micro-optparse/)

require 'micro-optparse'

options = Parser.new do |p|
  p.banner = <<-eos
    Given a set of CP or AIT experiments, pulls out the final point into a
    Tafel csv.
  eos
  p.option :filename_format, 'filename format, use %d to indicate data point placeholder', :default => 'cp%d_1.txt'
  p.option :uncompensated_resistance, 'uncompensated resistance in ohms', :default => 0.0
  p.option :data_start, 'starting data point, inserted in place of \%d', :default => 1, :short => 's'
  p.option :data_end, 'ending data point, inserted in place of \%d', :default => 13, :short => 'e'
end.process!

# configuration
datafiles = options[:filename_format]
data_start = options[:data_start].to_i
data_end = options[:data_end].to_i
uncompensated_resistance = options[:uncompensated_resistance].to_f #ohms

for i in data_start..data_end do
  cpfile = datafiles % i #generate filename of the current cp file.

  ##Get the anodic current for the run
  f = File.open(cpfile)
  f.each do |line|
    #Look for the anodic current line
    #ie. Anodic Current (A) = 1e-7
    if line =~ /Anodic Current \(A\) = ([\d.e-]+)\s*/
        $current = $1.to_f
        break
    end
  end
  f.close
  #Since we want a Tafel plot, take the log of the current:
  $logcurrent = Math.log10($current)

  ## Get the potential for the run
  #Get the last line of the file (which we are assuming is where equilibrium 
  #occurs).
  cmd = 'tail -n1 %s' % cpfile
  last_pt = `#{cmd}`
  #puts last_pt

  $potential = last_pt.split(',').last.strip()
  #Convert from scientific string to floating pt number.
  $potential = $potential.to_f 

  #iR correction on the potential. We subtract i*R_u from the potential.
  $potential = $potential - $current * uncompensated_resistance
  #puts 'Comp: %e ' % ($current * uncompensated_resistance)
    
  puts '%e, %e' % [$logcurrent, $potential]

end
