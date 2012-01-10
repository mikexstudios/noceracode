#!/usr/bin/env ruby
# Requires: micro-optparse (http://florianpilz.github.com/micro-optparse/)

require 'micro-optparse'

options = Parser.new do |p|
  p.banner = <<-eos
    Given a set of CP experiments, plots each of them in a grid (to maximize 
    visualization space).
  eos
  p.option :filename_format, 'filename format, use %d to indicate data point placeholder', :default => 'cp%d_1.txt'
  p.option :data_start, 'starting data point, inserted in place of \%d', :default => 1, :short => 's'
  p.option :data_end, 'ending data point, inserted in place of \%d', :default => 13, :short => 'e'
  p.option :output, 'output filename (in PDF)', :default => 'multicp.pdf'
end.process!

# configuration
$filename_format = options[:filename_format]
$data_start = options[:data_start].to_i
$data_end = options[:data_end].to_i
$output = options[:output]

$rscript = <<-eos
#!/usr/bin/env Rscript

pdf('#{output}')

par(mfrow = c(3,3)) #row, col

for(i in seq(#{data_start}, #{data_end})) {
     csv <- sprintf("#{filename_format}", i)
     cp <- read.csv(file = csv, skip = 18)
     #Because the second plot is smaller, we need to adjust the y-axis range here.
     plot(cp$Time.sec, cp$Potential.V,
          main = csv,
          xlab = "t (s)", ylab = "E (V)",
          #type = "l",
          cex = 0.4, #size of the points
          #ylim = c(0.85, 1.31)
          )
}

#Flush to file
dev.off()
eos

for i in $data_start..$data_end do
  cpfile = $filename_format % i #generate filename of the current cp file.

  puts cpfile
end
