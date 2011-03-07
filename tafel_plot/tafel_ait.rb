#!/usr/bin/env ruby

# configuration
datafiles = 'ait%d_1.txt'
data_start = 3
data_end = 12
uncompensated_resistance = 22.7 #ohms

for i in data_start..data_end do
  aitfile = datafiles % i #generate filename of the current cp file.

  ##Get the anodic current for the run
  f = File.open(aitfile)
  f.each do |line|
    #Look for the anodic current line
    #ie. Anodic Current (A) = 1e-7
    if line =~ /Init E \(V\) = ([\d.e-]+)\s*/
        $potential = $1.to_f
        break
    end
  end
  f.close

  ## Get the current for the run
  #Get the last line of the file (which we are assuming is where equilibrium 
  #occurs).
  cmd = 'tail -n1 %s' % aitfile
  last_pt = `#{cmd}`
  #puts last_pt

  $current = last_pt.split(',').last.strip()
  #Convert from scientific string to floating pt number.
  $current = $current.to_f 
  #If we have a negative current, then make it positive (the negative sign is
  #just a formality for signifying anodic current).
  $current = -1.0 * $current if $current < 0
  #Since we want a Tafel plot, take the log of the current:
  $logcurrent = Math.log10($current)

  #iR correction on the potential. We subtract i*R_u from the potential.
  $potential = $potential - $current * uncompensated_resistance
  #puts 'Comp: %e ' % ($current * uncompensated_resistance)
   
    
  puts '%e, %e' % [$logcurrent, $potential]

end
