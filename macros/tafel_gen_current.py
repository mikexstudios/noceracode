#!/usr/bin/env python

import sys
import re #for sub
from string import Template
import numpy #for arange

#Configuration variables
start_current = -7.0 #this is log() value
end_current = -2.0 #this is log() value
#step = 0.25 #this is log() value
step = 0.50 #this is log() value
each_runtime = 300 #seconds; runtime of each datapoint
initial_template_path = 'tafel_commented.mcr'

#Open template file and remove all comments (since electrochemical workstation
#can't handle them).
f = open(initial_template_path)
initial_template = f.read()
f.close()
initial_template = re.sub(r'\s*#.+\n', '\n', initial_template)

print '\xeb\x05\x00\x00'

#Change `ta` to the time we want for the run. 
#ta = 600 is a pretty good default.
template = Template('''
ia = %0.2e
ta = $runtime
run
save: cp%d''')
template = template.substitute(runtime = each_runtime)

print initial_template

#We add step to the end_current since arange does not end at our specified
#end_current, but rather one step before it.
range = numpy.arange(start_current, end_current + step, step)
for i, v in enumerate(range):
    #Convert from log(v) to v
    v = 10**v
    i += 1 #start counter at 1 instead of 0
    print template % (v, i)

#Now we have to do this again, but for the second run
print 'delay = 30' #short delay before doing again
print initial_template

template += '_2' #make the save file be filename_2
for i, v in enumerate(range):
    #Convert from log(v) to v
    v = 10**v
    i += 1 #start counter at 1 instead of 0
    print template % (v, i)
