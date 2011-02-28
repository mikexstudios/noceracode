#!/usr/bin/env python
# tafel_gen_current.py
# --------------------
# Usage: tafel_gen_current.py [configuration file] | tee [experiment].mcr
#
# Generates a macro (.mcr) file containing a series of chronopotentiometry 
# experiments for the purpose of collecting Tafel data. For CHI Electrochemical
# Workstation version 10.x.

import sys
from string import Template
import numpy #for arange

#Default configuration variables
start_current = -7.0 #this is log() value
end_current = -2.0 #this is log() value
step = 0.50 #this is log() value
each_runtime = 300 #seconds; runtime of each datapoint
num_passes = 2 #number of duplicate Tafel runs. Starts at 1

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
print 'Read control file successfully: '+control_file


#Templates
#CP technique settings
header_template = (
'tech: cp',      #CP = chronopotentiometry
'pn = p',        #initial current polarity in CP
'si = 1',        #sample interval in BE, CP (in s)
'cl = 1',        #number of segments in CV and CP
'eh = 3',        #high limit of potential in CV, CA, CP
'el = 0',        #low limit of potential in CV, CA, CP
                 #(even if we set time priority, the software still follows
                 # eh and ei! It's dumb!)
'priot',         #time priority in CP
)
header_template = '\n'.join(header_template)

#Change `ta` to the time we want for the run. 
#ta = 600 is a pretty good default.
run_template = Template('''
ia = ${current}
ta = ${runtime}
run
save: cp${run}_${pass_count}''')
#run_template = run_template.substitute(runtime = each_runtime)

#Electrochemical workstation is dumb and wants a binary COM file. Any other sane
#file format will not be read. So this little binary tidbit is for specifying
#the COM file beginning.
print '\xeb\x05\x00\x00'

#We add step to the end_current since arange does not end at our specified
#end_current, but rather one step before it.
current_range = numpy.arange(start_current, end_current + step, step)
for pass_count in range(1, num_passes + 1): #shift range to start at 1
    print header_template
    for i, v in enumerate(current_range):
        #Convert from log(v) to v
        v = 10**v
        i += 1 #start counter at 1 instead of 0
        #Format v in scientific mode
        v = '%0.2e' % v
        print run_template.substitute(current = v, run = i, 
                pass_count = pass_count, runtime = each_runtime)
    print
    print
