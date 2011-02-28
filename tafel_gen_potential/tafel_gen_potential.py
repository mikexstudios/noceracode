#!/usr/bin/env python
# tafel_gen_potential.py
# --------------------
# Usage: tafel_gen_potential.py [configuration file] | tee [experiment].mcr
#
# Generates a macro (.mcr) file containing a series of chronopotentiometry 
# experiments for the purpose of collecting Tafel data. For CHI Electrochemical
# Workstation version 10.x.

import sys
from string import Template
import numpy #for arange

#Default configuration variables (override these in the control file)
start_potential = 0.5 #in V
end_potential = 2.0 #in V
step = 0.20 #in V
each_runtime = 300 #seconds; runtime of each datapoint
num_passes = 2 #number of duplicate Tafel runs. Starts at 1
sensitivity = '1e-3' #sensitivity in A/V

try:
    control_file= sys.argv[1]
except IndexError:
    #NOTE: These print commands are commented out because the output of this
    #      script is redirected into a file.
    #print 'Usage: %s [controlfile]' % sys.argv[0]
    #print 'Since no control file specified, assuming the file is: control'
    control_file = 'control'

#Source the control file:
try:
    execfile(control_file)
except IOError: 
    print 'Error: '+control_file+' does not exist!'
    sys.exit(1)
#print 'Read control file successfully: '+control_file


#Templates
header_template = (
'tech: i-t',                #i-t = Amperiometric i-t Curve
'si = 1',                   #sample interval in BE, CP (in s)
'qt = 1',                   #quiet time (in s)
'sens = %s' % sensitivity,  #sensitivity in A/V
)
header_template = '\n'.join(header_template)

run_template = Template('''
ei = ${potential}
st = ${runtime}
run
save: ait${run}_${pass_count}''')


#Electrochemical workstation is dumb and wants a binary COM file. Any other sane
#file format will not be read. So this little binary tidbit is for specifying
#the COM file beginning.
print '\xeb\x05\x00\x00'

#Check which direction we should be stepping. If the starting potential is larger
#than the ending potential, then we should be decreasing the potential by each step.
if start_potential > end_potential:
    #We add step to the end_potential since arange does not end at our specified
    #end_potential, but rather one step before it.
    potential_range = numpy.arange(end_potential, start_potential + step, step)

    #Reverse the array. NOTE: We cannot use .reverse() since it is not
    #implemented in ndarray.
    potential_range = potential_range[::-1]
else:
    potential_range = numpy.arange(start_potential, end_potential + step, step)

for pass_count in range(1, num_passes + 1): #shift range to start at 1
    print header_template
    for i, v in enumerate(potential_range):
        i += 1 #start counter at 1 instead of 0
        print run_template.substitute(potential = v, run = i, 
                pass_count = pass_count, runtime = each_runtime)
    print
    print
