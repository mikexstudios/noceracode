#!/Users/mikeh/Documents/Labs/miniconda/bin/python2.7
#!/usr/bin/env python
# Given raw data files from CV (CH Instruments) and QCM (Gamry Resonator), 
# produce combined plots of both and worked up .csv files for import into
# other plotting software.

import os, re, math
from StringIO import StringIO

import pandas, numpy
import matplotlib
#matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib import ticker
import statsmodels.formula.api as sm


# Adjustable parameters
# NOTE: CVs need to be exported from CH Instrument's software with segment
# separators and time column.
cv_filename = '02cv 1.1V to -0.65V PtQCM in 4.5g KNO3.txt'
qcm_filename = '02qcm Au cap parafilm electodes.dta'
output_filename = 'cv_qcm.%s.pdf' #include %s
# Specify a CV start time since we typically wait a while for the QCM to
# stabilize before measuring data:
cv_start_time = 173.0 #s


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


# Parse CV segments into dataframes
cv_f = open(cv_filename, 'rU') #U to normalize all newlines to \n
cv_f.seek(0)
cv_str = cv_f.read()
m = re.findall(r'Segment \d+:(.+?)(?:\n\n|$)', cv_str, flags=re.DOTALL)
cv_segs = map(lambda x: pandas.read_csv(StringIO(x), 
    header=0, names=('potential', 'current', 'charge', 'time')), m)


# Parse QCM data
# Set the separator as \s so that the intital whitespace column doesn't get
# interpreted.
qcm_data = pandas.read_csv(qcm_filename, sep="\s", skiprows=14, header=0,
        names=('t', 'fs', 'fp', 'chisq', 'As', 'Ap'))
# Discard all data before the CV start time:
qcm_data = qcm_data[qcm_data.t >= cv_start_time].reset_index(drop = True)
qcm_data['t'] = qcm_data['t'] - qcm_data['t'][0] 
# Segment QCM data like CV segments
qcm_segs = []
for seg in cv_segs: 
    start_time = seg['time'].irow(0)
    end_time = seg['time'].irow(-1)
    qcm_seg = qcm_data[(qcm_data.t >= start_time) & (qcm_data.t <= end_time)]
    qcm_segs.append(qcm_seg)

# Add potential column to QCM data
# We want to add a potential column to the QCM data such that it corresponds to
# the potentials in the CVs. The difficulty is that the CV changes direction of
# potential, and it's a pain to try to calculate exactly when the potential
# changes. Thus, we use the strategy of doing a linear regression on each CV
# segment (potential = m * time + b). Then we use this equation to calculate
# potential for a given QCM time.
for cv_seg, qcm_seg in zip(cv_segs, qcm_segs):
    model = sm.ols('potential ~ time', data = cv_seg)
    results = model.fit()
    #results.params #contains the Intercept and time
    #print results.summary()
    qcm_seg['potential'] = results.params['time'] * qcm_seg['t'] + \
                           results.params['Intercept']

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
baseline_freq = numpy.average(qcm_segs[0]['fs'][0:5]) * 10**6 #Hz
for seg in qcm_segs:
    seg['delta_mass'] = seg['fs'].apply(lambda x: solve_mass_sauerbreyeq_for_freq(x * 10**6, baseline_freq = baseline_freq))


# Output data files
for i, seg in enumerate(cv_segs):
    seg.to_csv('cv_seg%.2i.csv' % i, index = False)
for i, seg in enumerate(qcm_segs):
    seg.to_csv('qcm_seg%.2i.csv' % i, index = False)


##########################################################
# Plot CV and QCM data together with potential as x-axis #
##########################################################
f, axes = plt.subplots(2, sharex = True)

# Set this to the number of segments to create a "rainbow" style plot
NUM_COLORS = len(qcm_segs)
cm = plt.get_cmap('gist_rainbow')
for ax in axes:
    ax.set_color_cycle([cm(1.*i/NUM_COLORS) for i in range(NUM_COLORS)])

formatters = [ticker.ScalarFormatter(useMathText=True) for ax in axes]
[formatter.set_scientific(True) for formatter in formatters]
[formatter.set_powerlimits((-1,1)) for formatter in formatters]
[ax.yaxis.set_major_formatter(formatter) for ax, formatter in zip(axes, formatters)]

[ax.xaxis.set_ticks_position('bottom') for ax in axes]
[ax.yaxis.set_ticks_position('left') for ax in axes]
[ax.xaxis.grid() for ax in axes] #vertical grid
axes[0].invert_xaxis() #only do it once

#ax.set_xlim(0, 300)
#ax.set_ylim(9.98037 + 3.0e-5, 9.98037 + 8e-5)

#axes[0].set_xlabel(r'$E$ (V vs. Ag/AgCl)')
#axes[0].set_ylabel("$i$ (A)")
for i, seg in enumerate(cv_segs): 
    axes[0].plot(seg['potential'], seg['current'], label='Seg %i' % i)

axes[1].set_xlabel(r'$E$ (V vs. Ag/AgCl)')
#axes[1].set_ylabel("$f$ (MHz)")
for i, seg in enumerate(qcm_segs): 
    axes[1].plot(seg['potential'], seg['fs'], label='Seg %i' % i)

axes[0].legend(loc = 'upper left')

# Post adjustments
axes[0].yaxis.offsetText.set_color('white')
axes[1].yaxis.offsetText.set_color('white')
f.tight_layout() #populates get_offset
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
f.tight_layout() #populates get_offset
ax2.set_ylabel("$\Delta$Mass (%s g)" % formatter2.get_offset())

f.tight_layout() #adjust margins so that figure is not cut off
f.subplots_adjust(hspace=0) #decrease vertical spacing between plots
f.savefig(output_filename % 'potential')



#####################################################
# Plot CV and QCM data together with time as x-axis #
#####################################################
f, axes = plt.subplots(2, sharex = True)

# Set this to the number of segments to create a "rainbow" style plot
NUM_COLORS = len(qcm_segs)
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
for i, seg in enumerate(cv_segs): 
    axes[0].plot(seg['time'], seg['current'], label='Seg %i' % i)

axes[1].set_xlabel(r'$t$ (s)')
#axes[1].set_ylabel("$f$ (MHz)")
for i, seg in enumerate(qcm_segs): 
    axes[1].plot(seg['t'], seg['fs'], label='Seg %i' % i)

axes[0].legend(loc = 'upper left')

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
f.savefig(output_filename % 'time')
