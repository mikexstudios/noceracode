#!/usr/bin/env ruby

# configuration
datafiles = 'cp%d_2.txt'
data_start = 1
data_end = 13
uncompensated_resistance = 25.5 #ohms

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
