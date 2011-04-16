#!/usr/bin/env ruby
# tafel_workup.rb
# An all in one script that ties together the tafel data workup process. Supposed
# to simplify the slightly tedious process of copying and modifying files around.

#Default configuration variables (override these in the control file)
$uncompensated_resistance = 20
$plot_title = '5 layer Mn in 0.5 M KPi, pH 2.49; H->L, 300s/pt - Pass #{pass} (04/02/2011)'
$pass_colors = ['red', 'orange', 'cadetblue1', 'green', 'blue', 'purple', 'black']
$combined_ylim = [0.58, 1.03]

$tafel_gen_script = 'tafel_cp.sh'

$templates_path = './' #default to current directory
$tafel_plot_template = 'tafel_template.R'
$tafel_combined_template = 'tafel_combined_template.R'

if File.exists?('control')
    eval(File.open('control').read())
end

#Point the templates to full path
$tafel_plot_template = File.join($templates_path, $tafel_plot_template)
$tafel_combined_template = File.join($templates_path, $tafel_combined_template)

# Generate tafel_cp.sh file
# First, determine the number of passes and number of datapoints in each pass.
$pass = {} #dict with pass int as key and greatest datapoint as value
Dir['cp*.txt'].each do |filename|
    #Extract the pass and datapoint from each filename
    #.scan outputs an array inside an array if there are multiple areas to be
    #matched. We only have one possible area to match.
    match = filename.scan(/cp(\d+)_(\d+).txt/)[0]
    datapoint = match[0].to_i
    pass = match[1].to_i

    #Place each pass number as dictionary key with highest datapoint as value
    if $pass[pass] == nil or $pass[pass] < datapoint
        $pass[pass] = datapoint
    end
end

#For each pass, write to tafel gen file
if not File.exists?($tafel_gen_script)
    f = File.new($tafel_gen_script, 'w')
    f.puts <<-eol
#!/bin/bash
UNCOMPENSATED_RESISTANCE=#{$uncompensated_resistance}
    eol
    
    $pass.each_pair do |pass, max_datapoint|
        #For now, let's not worry about setting datapoint range.
        #(1..max_datapoint).each do |datapoint|
            f.puts "tafel_cp -f 'cp%d_#{pass}.txt' -u $UNCOMPENSATED_RESISTANCE | tee tafel_#{pass}.csv"
            f.puts 'echo'
        #end
    end
    f.chmod(0755)
    f.close()
    
    puts 'Generated tafel_cp.sh file:'
    puts `cat tafel_cp.sh`
    
    puts 'Make sure to run tafel_cp.sh and that all of the tafel files are generated.'
    puts 'Then press any key to continue...'
    gets
else
    puts 'Skipped tafel_cp.sh generation since already exists.'
end


#Generate tafel plot file for each of the passes from our Tafel template file.
#The template file includes sample commented out lines for line fitting.
f = File.open($tafel_plot_template, 'r')
tafel_individual_template = f.read()
f.close()
$pass.each_key do |pass|
    plot_file = 'tafel_%i.R' % pass
    plot_title = eval('%Q[' + $plot_title + ']')

    if not File.exists?(plot_file)
        pf = File.new(plot_file, 'w')
        pf.puts eval('%Q['+ tafel_individual_template + ']')
        pf.chmod(0755)
        pf.close()

        puts 'Generated tafel_%i.R file.' % pass
    else
        puts 'Skipped generation of tafel_%i.R file since already exists.' % pass
    end
end
puts 'Plot each file with the command plot_tafel [pass].'
puts 'Edit each file individually to enable line-fitting.'
puts 'Then press any key to continue...'
gets


#Now that the user has edited each of the plot files with the line fitting, let's
#take that data and put it into the combined tafel plot file. First, process the
#combined template file:
if not File.exists?('tafel_combined.R')
    ctf = File.open($tafel_combined_template, 'r')
    tafel_combined_template = ctf.read()
    ctf.close()
    
    #Now pull out the relevant blocks
    beginning_template = tafel_combined_template.slice(/(.+)#FIRST PLOT/m, 1)
    first_plot_template = tafel_combined_template.slice(/#FIRST PLOT \(do not remove\)(.+)#END FIRST PLOT/m, 1)
    subsequent_plot_template = tafel_combined_template.slice(/#SUBSEQUENT PLOTS \(do not remove\)(.+)#END SUBSEQUENT PLOTS/m, 1)
    legend_template = tafel_combined_template.slice(/#LEGEND \(do not remove\)(.+)#END LEGEND/m, 1)
    end_template = tafel_combined_template.slice(/#END LEGEND(.+)/m, 1)
    
    #Initialize legend vars
    labels = []
    colors = []
    
    #Open plot combined file for writing
    f = File.new('tafel_combined.R', 'w')
    f.puts beginning_template
    $pass.each_key do |pass|
        plot_file = 'tafel_%i.R' % pass
        color = $pass_colors[pass - 1] #since index starts at zero
    
        #Get the linear fit region from the individual tafel files.
        tf = File.open(plot_file, 'r')
        individual_tafel = tf.read()
        tf.close()
        linear_fit = individual_tafel.slice(/# PLOT SETTINGS \(do not remove this line\)(.+)# END PLOT SETTINGS/m, 1)
        #Replace any set color with this pass' color
        linear_fit.gsub!(/col='\w+'/, "col='#{color}'")
    
        if pass == 1
            #NOTE: Crude hack
            plot_title = $plot_title.gsub(/(Pass)?\s*#\{pass\}/, 'combined')
            f.puts eval('%Q['+ first_plot_template + ']')
        else
            f.puts eval('%Q['+ subsequent_plot_template + ']')
        end
    
        labels.push("'Pass %i'" % pass)
        colors.push("'%s'" % color)
    end
    labels = labels.join(", \n")
    colors = colors.join(", \n")
    f.puts eval('%Q['+ legend_template + ']')
    f.puts end_template
    f.chmod(0755)
    f.close()

    puts 'Successfully generated tafel_combined.R'
    puts 'Plot with the command plot_tafel combined'
else
    puts 'Skipped generation of tafel_combined.R because file exists.'
end
