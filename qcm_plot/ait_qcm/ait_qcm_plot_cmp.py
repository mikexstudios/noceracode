#!/Users/mikeh/Documents/Labs/miniconda/bin/python2.7
#!/usr/bin/env python
# Given raw data files from AIT (CH Instruments) and QCM (Gamry Resonator), 
# produce combined plots of both and worked up .csv files for import into
# other plotting software.

import os, re, math
from StringIO import StringIO

import pandas, numpy
import matplotlib
#matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib import ticker
#import statsmodels.formula.api as sm


# Adjustable parameters
expts = [
    { 
        'legend_title': 'AIT -0.4 (p45 02a)',
        'ait_filename': '02ait -0.4V PtQCM in 0.5mM Mn, 4.5g KNO3.txt',
        'qcm_filename': '02qcm.dta',
        'start_time': 71.0, #s
    },
    { 
        'legend_title': 'AIT -0.4 (p45 01a)',
        'ait_filename': '../01ait/01ait -0.4V PtQCM in 0.5mM Mn, 4.5g KNO3.txt',
        'qcm_filename': '../01ait/01ait.dta',
        'start_time': 31.8, #s
    },
]
output_filename = 'ait_qcm_cmp.png' 


# Matplotlib base style
matplotlib.rcParams['figure.figsize'] = (10, 10)
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


# Parse AIT into dataframe
def parse_ait_data(filename):
    ait_data = pandas.read_csv(filename, skiprows=16, header=0, names=('time',
                            'current', 'charge'))
    return ait_data

# Parse QCM data
# Set the separator as \s so that the intital whitespace column doesn't get
# interpreted.
def parse_qcm_data(filename, start_time = 0.0):
    qcm_data = pandas.read_csv(filename, sep="\s", skiprows=14, header=0,
            names=('t', 'fs', 'fp', 'chisq', 'As', 'Ap'))
    # Discard all data before the AIT start time:
    qcm_data = qcm_data[qcm_data.t >= start_time].reset_index(drop = True)
    qcm_data['t'] = qcm_data['t'] - qcm_data['t'][0] 
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
    expt['ait_data'] = parse_ait_data(expt['ait_filename'])
    expt['qcm_data'] = parse_qcm_data(expt['qcm_filename'], start_time = expt['start_time'])
    expt['qcm_data'] = calculate_delta_mass(expt['qcm_data'])
    # We average a few initial points to establish the baseline frequency
    expt['qcm_baseline_freq'] = numpy.average(expt['qcm_data']['fs'][0:5]) * 10**6 #Hz


# Output data files
#mp_data.to_csv('mp.csv', index = False)
#qcm_data.to_csv('qcm.csv', index = False)


##################################
# Plot AIT and QCM data together #
##################################
f, axes = plt.subplots(2, sharex = True)

# Set this to the number of segments to create a "rainbow" style plot
NUM_COLORS = len(expts)
cm = plt.get_cmap('gist_rainbow')
for ax in axes:
    ax.set_color_cycle([cm(1.*i/NUM_COLORS) for i in range(NUM_COLORS)])

formatters = [ticker.ScalarFormatter(useMathText=True) for ax in axes]
[formatter.set_scientific(True) for formatter in formatters]
[formatter.set_powerlimits((-1,1)) for formatter in formatters]
[ax.yaxis.set_major_formatter(formatter) for ax, formatter in zip(axes, formatters)]

[ax.xaxis.set_ticks_position('bottom') for ax in axes]
[ax.yaxis.set_ticks_position('left') for ax in axes]
[ax.xaxis.grid() for ax in axes]

#ax.set_xlim(0, 300)
#ax.set_ylim(9.98037 + 3.0e-5, 9.98037 + 8e-5)

#axes[0].set_xlabel(r'$E$ (V vs. Ag/AgCl)')
#axes[0].set_ylabel("$i$ (A)")
axes[0].set_ylim(0e-5, 2e-5)
for expt in expts:
    axes[0].plot(expt['ait_data']['time'], expt['ait_data']['current'], 
            label = expt['legend_title'])

axes[1].set_xlabel(r'$t$ (s)')
#axes[1].set_ylabel("$f$ (MHz)")
for expt in expts:
    axes[1].plot(expt['qcm_data']['t'], expt['qcm_data']['fs'], 
            label = expt['legend_title'])

axes[0].legend(loc = 'upper right')

# Post adjustments
axes[0].yaxis.offsetText.set_color('white')
axes[1].yaxis.offsetText.set_color('white')
f.tight_layout() #need for populating get_offset
axes[0].set_ylabel("$i$ (%s A)" % formatters[0].get_offset())
axes[1].set_ylabel("$f$ (%s MHz)" % formatters[1].get_offset())

# Second y-axis
ax2 = axes[1].twinx() #Must come after first plot!
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
