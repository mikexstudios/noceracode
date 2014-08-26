#!/usr/bin/env python
# Given Tafel csv, converted from AIT files.
import re, os
import pandas, numpy
import matplotlib
import matplotlib.pyplot as plt
from matplotlib import ticker
import statsmodels.formula.api as sm

# Adjustable parameters
expts = [
    { 
        'legend_title': 'Pass 1',
        'filename': 'p01.csv',
    },
    { 
        'legend_title': 'Pass 2',
        'filename': 'p02.csv',
    },
]
output_filename = 'tafel.pdf' 
pH = 7.0
E0_water_ox = 1.23 - 0.059 * pH #V for NHE
def get_overpotential(potential):
    return potential - E0_water_ox


#########################
# Set matplotlib styles #
#########################
matplotlib.rcParams['figure.figsize'] = (8, 6)
matplotlib.rcParams['lines.linewidth'] = 3
matplotlib.rcParams['font.family'] = 'sans-serif'
matplotlib.rcParams['font.sans-serif'] = ['Arial']
matplotlib.rcParams['text.usetex'] = False
matplotlib.rcParams['font.size'] = 28
matplotlib.rcParams['mathtext.fontset'] = 'stixsans'
matplotlib.rcParams['mathtext.default'] = 'it'

matplotlib.rcParams['axes.linewidth'] = 2
matplotlib.rcParams['axes.labelsize'] = 'large'
#matplotlib.rcParams['axes.xmargin'] = 0
#matplotlib.rcParams['axes.formatter.use_mathtext'] = True

matplotlib.rcParams['xtick.major.pad'] = 8
matplotlib.rcParams['ytick.major.pad'] = 8
matplotlib.rcParams['xtick.major.size'] = 20
matplotlib.rcParams['ytick.major.size'] = 20
matplotlib.rcParams['xtick.minor.size'] = 12
matplotlib.rcParams['ytick.minor.size'] = 12
matplotlib.rcParams['xtick.major.width'] = 2
matplotlib.rcParams['ytick.major.width'] = 2
matplotlib.rcParams['xtick.minor.width'] = 2
matplotlib.rcParams['ytick.minor.width'] = 2

matplotlib.rcParams['legend.fontsize'] = 14
matplotlib.rcParams['legend.markerscale'] = 0.7
matplotlib.rcParams['legend.frameon'] = False
matplotlib.rcParams['legend.labelspacing'] = 0.25
matplotlib.rcParams['legend.numpoints'] = 1 #single marker instead of double



#############
# Plot data #
#############
f, ax = plt.subplots(1)

# Set this to the number of segments to create a "rainbow" style plot
NUM_COLORS = len(expts)
cm = plt.get_cmap('gist_rainbow') #or hsv or Set1
ax.set_color_cycle([cm(1.*i/NUM_COLORS) for i in range(NUM_COLORS)])
colors = [cm(1.*i/NUM_COLORS) for i in range(NUM_COLORS)]

#formatter = ticker.ScalarFormatter(useMathText=True)
#formatter.set_scientific(True)
#formatter.set_powerlimits((-1,1))
#ax.yaxis.set_major_formatter(formatter)

# Locators define where the tick marks appear
ax.xaxis.set_major_locator(ticker.MaxNLocator(nbins=3, integer=False, prune=None))
ax.xaxis.set_minor_locator(ticker.AutoMinorLocator(n=2))
ax.yaxis.set_major_locator(ticker.MaxNLocator(nbins=4, integer=False, prune=None))
ax.yaxis.set_minor_locator(ticker.AutoMinorLocator(n=2))

ax.xaxis.set_ticks_position('bottom')
ax.yaxis.set_ticks_position('left')
#ax.xaxis.grid()

ax.set_xlim(-5.5, -3)
#ax.set_ylim(1.1, 1.3)

ax.set_ylabel(r'$E$ / V (vs. NHE)')
ax.set_xlabel(r'$\log (\ j_{\mathrm{ac}} \ / \ \mathrm{mA/cm^2})$')

for expt in expts:
    color = colors.pop(0)
    tafel_data = pandas.read_csv(expt['filename'], skiprows=0, header='infer')

    # Use blank plot initially to get axis limits
    ax.plot(tafel_data['current.norm.log'], tafel_data['potential.nhe'], 
            linestyle='None') 
    xlims = ax.get_xlim()

    # Linear fit
    model = sm.ols('Q("potential.nhe") ~ Q("current.norm.log")', data = tafel_data)
    results = model.fit()
    #print results.summary()
    slope = results.params['Q("current.norm.log")'] * 1000.0 #convert to mV/dec
    expt['legend_title'] += ' (%0.2f mV/d)' % slope

    # We want to create a line that spans the full plot view, so let's add 
    # x-min and x-max to the dataframe and then have the fitting model generate
    # the y-points to plot a line.
    temp_df = tafel_data.append([{'current.norm.log': xlims[0]}, 
        {'current.norm.log': xlims[1]}], ignore_index=True)
    ax.plot(temp_df['current.norm.log'], results.predict(temp_df), color = color)

    ax.plot(tafel_data['current.norm.log'], tafel_data['potential.nhe'], 
            linestyle='None', marker='s', markersize=18, markerfacecolor = color,  
            markeredgewidth=2, markeredgecolor="black", alpha=0.8,
            label = expt['legend_title'])

    ax.set_xlim(xlims[0], xlims[1]) #plotting the line expands plot, so move it back


ax.legend(loc = 'upper left')

# Second y-axis
ax2 = ax.twinx() #Must come after first plot!
ax2.yaxis.set_major_locator(ticker.MaxNLocator(nbins=5, integer=False, prune=None))
#ax2.yaxis.set_minor_locator(ticker.AutoMinorLocator(n=2))
ax2.set_ylim(get_overpotential(y) for y in ax.get_ylim())
f.tight_layout() #need for populating get_offset
ax2.set_ylabel("$\eta_\mathrm{pH \ %0.1f}$ / V" % pH)

f.tight_layout()
f.savefig(output_filename)
