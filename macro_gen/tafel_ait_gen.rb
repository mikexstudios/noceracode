#!/usr/bin/env ruby

# Experiment variables

@potential_range = (1.20..0.80) #V, also controls direction of scan
@step = (@potential_range.last - @potential_range.first) / 12.0 
#@sample_time = 300 #sec, of each point
@sample_time = lambda do |p|
  t = 10 #normal run time in s
  t = 300 if p == @potential_range.first #anodization of first point
  return t
end
#The sensitivity must be specified as 1e-n where n = [1, 12], because that is
#what the potentiostat can handle. We use a lambda so that sensitivity is
#dynamic as a function of potential.
#@sensitivity = 1e-4 #A/V
@sensitivity = lambda do |p|
  s = 1e-5 if p <= @potential_range.first
  s = 1e-6 if p <= 0.90
  return s
end
@sample_interval = 1 #sec between each point sample
@num_passes = 1
@ir_comp = 16 #ohm
#Save filename in sprintf format. Leave out .bin/.txt.
#<pass> -> denotes the pass number
#<run>  -> denotes the run number
@save_filename_format = 'ait_p%02<pass>i_%02<run>i' #e.g. ait_p01_02


# Internal variables (do not change)
#@output_mcr = $1 ||= 'tafel_ait.mcr' #the macro filename to generate
@output_mcr = 'tafel_ait.mcr' #the macro filename to generate
@save_folder = Dir.pwd #set to current working directory


# Generation of output. First, we write to a temporary file which will be
# deleted when the number of characters have been counted.

# Hackish: Monkey patching File.puts to output windows line endings since the
# macro will be loaded into a windows program.
class File
  def puts(*s) #unlimited arguments
    s = [''] if s.empty? #make sure puts with no arguments gives new line
    s.each do |i|
      self.write(i)
      self.write("\r\n")
    end
  end
end


File.open('%s.temp' % @output_mcr, 'w') do |f|
  f.puts
  f.puts '# WARNING: Do not edit this file directly in a text editor since'
  f.puts '# the first 4 bytes of the file specifies the total number of '
  f.puts '# subsequent bytes to read. This must be calculated after each '
  f.puts '# file save. Use the generation script or edit inside of CHI.' 
  f.puts

  # Initial settings
  f.puts '# Initial settings'
  f.puts 'folder = %s' % @save_folder
  f.puts

  # Technique settings
  f.puts '# Technique settings'
  f.puts 'tech = i-t'
  f.puts 'si = %g' % @sample_interval
  f.puts 'qt = 0' #quiescent time before run
  #sensitivity will be set depending on potential
  f.puts

  # IR compensation settings
  # TODO: Make sure that this setting carries over for all runs
  f.puts '# IR compensation settings'
  f.puts 'mir = %g' % @ir_comp
  f.puts 'ircompon' #to turn off, use: ircompoff
  f.puts
  f.puts

  # Individual run settings
  for pass in 1..@num_passes
    f.puts '# Pass %02i' % pass
    #Since we can't have negative step values (ie. for when we decrement), 
    #we need to generate our potentials by manually specifying the start and
    #end values of our range.
    potentials = (@potential_range.first).step(@potential_range.last, @step)
    potentials = potentials.to_a.map {|x| x.round(3)}
    potentials.each_with_index do |p, i|
      f.puts 'ei = %g' % p
      #Dynamic time and sensitivity
      f.puts 'st = %g' % @sample_time.call(p)
      f.puts 'sens = %g' % @sensitivity.call(p)
      f.puts 'run'
      f.puts 'save  = %s' % (@save_filename_format % {pass: pass, run: i+1})
      f.puts 'tsave = %s' % (@save_filename_format % {pass: pass, run: i+1})
      f.puts
    end
    f.puts
    f.puts
  end
end


# Calculate number of characters. Read the generated file, calculate the number
# of characters in the macro and prepend it.
File.open('%s.temp' % @output_mcr) do |ftemp|
  s = ftemp.read()

  File.open(@output_mcr, 'w') do |f|
    f.write Array(s.length).pack('V') #write as little endian
    f.write s
  end
end
File.delete('%s.temp' % @output_mcr)
