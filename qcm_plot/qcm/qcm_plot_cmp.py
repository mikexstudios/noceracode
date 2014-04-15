#!/Users/mikeh/Documents/Labs/miniconda/bin/python2.7
#!/usr/bin/env python
# Given raw data files from QCM (Gamry Resonator), plot frequency and mass.

import os, re, math
from StringIO import StringIO

import pandas, numpy
import matplotlib
#matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib import ticker
import statsmodels.formula.api as sm


# Adjustable parameters
expts = [
    { 
        'legend_title': 'AIT 1.0V (p48 03a)',
        'qcm_filename': '../03ait/03ait.dta',
    },
    { 
        'legend_title': 'AIT 1.0V (p48 04a)',
        'qcm_filename': '../04ait/04ait waterox again.dta',
    },
]
output_filename = 'qcm_cmp.png' 

# Matplotlib base style
matplotlib.rcParams['figure.figsize'] = (10, 6)
matplotlib.rcParams['lines.linewidth'] = 3
matplotlib.rcParams['font.family'] = 'sans-serif'
matplotlib.rcParams['font.sans-serif'] = ['Arial']
matplotlib.rcParams['text.usetex'] = False
matplotlib.rcParams['font.size'] = 25
matplotlib.rcParams['mathtext.fontset'] = 'stixsans'
matplotlib.rcParams['mathtext.default'] = 'it'

matplotlib.rcParams['axes.linewidth'] = 2
matplotlib.rcParams['axes.labelsize'] = 'large'
#matplotlib.rcParams['axes.xmargin'] = 0
#matplotlib.rcParams['axes.formatter.use_mathtext'] = True

matplotlib.rcParams['xtick.major.pad'] = 8
matplotlib.rcParams['ytick.major.pad'] = 8
matplotlib.rcParams['xtick.major.size'] = 12
matplotlib.rcParams['ytick.major.size'] = 12
matplotlib.rcParams['xtick.minor.size'] = 6
matplotlib.rcParams['ytick.minor.size'] = 6
matplotlib.rcParams['xtick.major.width'] = 2
matplotlib.rcParams['ytick.major.width'] = 2

matplotlib.rcParams['legend.fontsize'] = 'small'
matplotlib.rcParams['legend.frameon'] = False
matplotlib.rcParams['legend.labelspacing'] = 0.25


# Parse QCM data
def parse_qcm_data(filename):
    # Set the separator as \s so that the intital whitespace column doesn't get
    # interpreted.
    qcm_data = pandas.read_csv(filename, sep="\s", skiprows=14, header=0,
            names=('t', 'fs', 'fp', 'chisq', 'As', 'Ap'))
    return qcm_data

# Calculate mass change with Sauerbrey equation
# See: https://en.wikipedia.org/wiki/Sauerbrey_equation
def solve_mass_sauerbreyeq(delta_freq, resonant_freq = 10.0e6): #Hz
    # These parameters are taken from the ICM datasheet for the crystal
    A = 0.205 #cm^2
    mu = 2.947 * 10**11 #g/(cm s^2)
    p = 2.648 #g/cm^3
    return (delta_freq * A * math.sqrt(mu * p))/(-2 * resonant_freq**2)
def solve_mass_sauerbreyeq_for_freq(freq, baseline_freq = None, resonant_freq = 10e6): #Hz
    baseline_mass = 0.0
    if baseline_freq is not None:
        baseline_mass = solve_mass_sauerbreyeq_for_freq(baseline_freq)
    return solve_mass_sauerbreyeq(freq - resonant_freq) - baseline_mass
def calculate_delta_mass(qcm_data):
    # We average a few initial points to establish the baseline frequency
    baseline_freq = numpy.average(qcm_data['fs'][0:5]) * 10**6 #Hz
    qcm_data['delta_mass'] = qcm_data['fs'].apply(lambda x: solve_mass_sauerbreyeq_for_freq(x * 10**6, baseline_freq = baseline_freq))
    return qcm_data


# Apply to all defined experiments
for expt in expts:
    expt['qcm_data'] = parse_qcm_data(expt['qcm_filename'])
    expt['qcm_data'] = calculate_delta_mass(expt['qcm_data'])
    # We average a few initial points to establish the baseline frequency
    expt['qcm_baseline_freq'] = numpy.average(expt['qcm_data']['fs'][0:5]) * 10**6 #Hz


# Output data files
#qcm_data.to_csv('%s.csv' % os.path.splitext(qcm_filename)[0], index = False)


#####################################
# Plot QCM data with time as x-axis #
#####################################
f, ax = plt.subplots(1)

# Set this to the number of segments to create a "rainbow" style plot
NUM_COLORS = len(expts)
cm = plt.get_cmap('gist_rainbow')
ax.set_color_cycle([cm(1.*i/NUM_COLORS) for i in range(NUM_COLORS)])

formatter = ticker.ScalarFormatter(useMathText=True)
formatter.set_scientific(True)
formatter.set_powerlimits((-1,1))
ax.yaxis.set_major_formatter(formatter)

ax.xaxis.set_ticks_position('bottom')
ax.yaxis.set_ticks_position('left')
ax.xaxis.grid()

#ax.set_xlim(200, 205)
#ax.set_ylim(9.9802 + 4.0e-4, 9.9802 + 6e-4)

#axes[0].set_xlabel(r'$E$ (V vs. Ag/AgCl)')
#axes[0].set_ylabel("$i$ (A)")
ax.set_xlabel(r'$t$ (s)')
for expt in expts:
    ax.plot(expt['qcm_data']['t'], expt['qcm_data']['fs'], 
            label = expt['legend_title'])

ax.legend(loc = 'upper left')

# Post adjustments
ax.yaxis.offsetText.set_color('white')
f.tight_layout() #need for populating get_offset
ax.set_ylabel("$f$ (%s MHz)" % formatter.get_offset())

# Second y-axis
ax2 = ax.twinx() #Must come after first plot!
formatter2 = ticker.ScalarFormatter(useMathText=True)
formatter2.set_scientific(True) 
formatter2.set_powerlimits((-1,1)) 
ax2.yaxis.set_major_formatter(formatter2) 
ax2.yaxis.offsetText.set_color('white')
ax2.set_ylim(solve_mass_sauerbreyeq_for_freq(y * 10**6, baseline_freq = expts[0]['qcm_baseline_freq']) for y in ax.get_ylim())
f.tight_layout() #need for populating get_offset
ax2.set_ylabel("$\Delta$Mass (%s g)" % formatter2.get_offset())

f.tight_layout()
f.subplots_adjust(hspace = 0) #decrease vertical spacing between plots
f.savefig(output_filename)
