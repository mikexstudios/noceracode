#!/Users/mikeh/Documents/Labs/miniconda/bin/python2.7
#!/usr/bin/env python
# Given raw data files from MP (CH Instruments) and QCM (Gamry Resonator), 
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
mp_filename = '01mp 0.9V 3s -0.4V 2s, AuQCM in 4.5g KNO3.txt'
qcm_filename = '01qcm Au cap parafilm electodes.dta'
output_filename = 'mp_qcm.%s.png' #include %s
# Specify a MP start time since we typically wait a while for the QCM to
# stabilize before measuring data:
mp_start_time = 181.0 #s
# Start and end times for zoomed plot
zoom_times = (0, 100) #s


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


# Parse MP into dataframes
mp_data = pandas.read_csv(mp_filename, skiprows=20, header=0, names=('time',
                            'current', 'charge'))


# Parse QCM data
# Set the separator as \s so that the intital whitespace column doesn't get
# interpreted.
qcm_data = pandas.read_csv(qcm_filename, sep="\s", skiprows=14, header=0,
        names=('t', 'fs', 'fp', 'chisq', 'As', 'Ap'))
# Discard all data before the CV start time:
qcm_data = qcm_data[qcm_data.t >= mp_start_time].reset_index(drop = True)
qcm_data['t'] = qcm_data['t'] - qcm_data['t'][0] 


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
# We average a few initial points to establish the baseline frequency
baseline_freq = numpy.average(qcm_data['fs'][0:5]) * 10**6 #Hz
qcm_data['delta_mass'] = qcm_data['fs'].apply(lambda x: solve_mass_sauerbreyeq_for_freq(x * 10**6, baseline_freq = baseline_freq))


# Output data files
#mp_data.to_csv('mp.csv', index = False)
#qcm_data.to_csv('qcm.csv', index = False)


###########################################
# Plot MP and QCM data together full time #
###########################################
f, axes = plt.subplots(2, sharex = True)

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
axes[0].plot(mp_data['time'], mp_data['current'], color = 'red')

axes[1].set_xlabel(r'$t$ (s)')
#axes[1].set_ylabel("$f$ (MHz)")
axes[1].plot(qcm_data['t'], qcm_data['fs'], color = 'blue')

#axes[0].legend(loc = 'upper left')

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
ax2.set_ylim(solve_mass_sauerbreyeq_for_freq(y * 10**6, baseline_freq = baseline_freq) for y in ax.get_ylim())
f.tight_layout() #need for populating get_offset
ax2.set_ylabel("$\Delta$Mass (%s g)" % formatter2.get_offset())

f.tight_layout()
f.subplots_adjust(hspace = 0) #decrease vertical spacing between plots
f.savefig(output_filename % 'full')


###########################################
# Plot MP and QCM data together zoomed in #
###########################################
f, axes = plt.subplots(2, sharex = True)

formatters = [ticker.ScalarFormatter(useMathText=True) for ax in axes]
[formatter.set_scientific(True) for formatter in formatters]
[formatter.set_powerlimits((-1,1)) for formatter in formatters]
[ax.yaxis.set_major_formatter(formatter) for ax, formatter in zip(axes, formatters)]

[ax.xaxis.set_ticks_position('bottom') for ax in axes]
[ax.yaxis.set_ticks_position('left') for ax in axes]
[ax.xaxis.grid() for ax in axes]

#ax.set_xlim(0, 300)
#ax.set_ylim(9.98037 + 3.0e-5, 9.98037 + 8e-5)

# The reason we slice the data here instead of setting xlim is so that
# matplotlib can autoscale the data for us. Apparently, it cannot autoscale
# the y-axis after xlim has been set.
sliced_mp_data = mp_data[(mp_data['time'] >= zoom_times[0]) & (mp_data['time'] <= zoom_times[1])]
sliced_qcm_data = qcm_data[(qcm_data['t'] >= zoom_times[0]) & (qcm_data['t'] <= zoom_times[1])]

#axes[0].set_xlabel(r'$E$ (V vs. Ag/AgCl)')
#axes[0].set_ylabel("$i$ (A)")
axes[0].plot(sliced_mp_data['time'], sliced_mp_data['current'], color = 'red')

axes[1].set_xlabel(r'$t$ (s)')
#axes[1].set_ylabel("$f$ (MHz)")
axes[1].plot(sliced_qcm_data['t'], sliced_qcm_data['fs'], color = 'blue')

#axes[0].legend(loc = 'upper left')

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
ax2.set_ylim(solve_mass_sauerbreyeq_for_freq(y * 10**6, baseline_freq = baseline_freq) for y in ax.get_ylim())
f.tight_layout() #need for populating get_offset
ax2.set_ylabel("$\Delta$Mass (%s g)" % formatter2.get_offset())

f.tight_layout()
f.subplots_adjust(hspace = 0) #decrease vertical spacing between plots
f.savefig(output_filename % 'zoom')
