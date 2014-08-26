#!/usr/bin/env python
# Script for converting a series of AIT data files to a Tafel CSV
import re, os
import pandas, numpy

# Parameters
base_path = '../'
surface_area = 1.0 #cm^2
potential_reference_correction = 0.197 #added to potential
pH = 7.0
E0_water_ox = 1.23 - 0.059 * pH #V for NHE

# Helper functions
def get_potential(ait_path):
    inite_re = re.compile(r'^Init E \(V\) = (.+)$')
    with open(ait_path, 'r') as f:
        for line in f:
            m = inite_re.search(line)
            if m:
                potential = float(m.group(1))
                break
    return potential


def get_current(ait_path, average_last = 5, skiprows = 17, header = 0, 
        names = ('potential', 'current'), **kwargs):
    ait_data = pandas.read_csv(ait_path, skiprows = skiprows, 
            header = header, names = names, **kwargs)
    #ait_data = ait_data[1:] #get rid of first empty row
    # Average the last few seconds of curent
    last = ait_data.tail(n = average_last).mean()
    return last['current'].mean()

def tafel_workup(tafel_df):
    #Normalize the current to surface area
    tafel_df['current.norm'] = tafel_df['current'] / surface_area

    #Take log10 of current, make sure it's negative
    tafel_df['current.norm.log'] = numpy.log10(-1 * tafel_df['current'])

    #Correct potential to NHE
    tafel_df['potential.nhe'] = tafel_df['potential'] + potential_reference_correction

    #Calculate overpotentials
    tafel_df['overpotential'] = tafel_df['potential.nhe'] - E0_water_ox

    return(tafel_df)


tafel = pandas.DataFrame()
ait_files = ['ait_p%02i_%02i.txt' % (1, i) for i in range(1, 13 + 1) ]
for i, ait_file in enumerate(ait_files):
    print '.',
    ait_file = os.path.join(base_path, ait_file)
    potential = get_potential(ait_file)
    if i <= 0:
        current = get_current(ait_file, average_last = 10)
    else:
        current = get_current(ait_file)
    tafel = tafel.append({'potential': potential, 'current': current},
                         ignore_index = True)
tafel = tafel_workup(tafel)
tafel.to_csv('p01.csv', index = False)


tafel = pandas.DataFrame()
ait_files = ['ait_p%02i_%02i.txt' % (2, i) for i in range(1, 13 + 1) ]
for i, ait_file in enumerate(ait_files):
    print '.',
    ait_file = os.path.join(base_path, ait_file)
    potential = get_potential(ait_file)
    if i <= 0:
        current = get_current(ait_file, average_last = 10)
    else:
        current = get_current(ait_file)
    #df = pandas.DataFrame({})
    tafel = tafel.append({'potential': potential, 'current': current},
                         ignore_index = True)
tafel = tafel_workup(tafel)
tafel.to_csv('p02.csv', index = False)
