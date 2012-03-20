#!/usr/bin/env ruby

require 'serialport'

sp = SerialPort.new(4, 9600)
sp.read_timeout = 100
sp.write_timeout = 1
puts sp.read_timeout
puts sp.write_timeout
sp.write "getmeas\r\n"
puts sp.readline
total = ''
sp.close
sp = SerialPort.new(4, 9600)
sp.read_timeout = 100
sp.write_timeout = 10
sp.write "getmeas\r\n"
puts sp.readline
puts 'here'
sp.write "getmeas\r\n"
puts 'here2'
puts sp.readline
#puts sp.read

#sp.each_line('\n') do |line|
#  puts line
#end

#puts sp.readlines
#while true
#  puts sp.gets('\n')
#  puts
#  c = sp.getc
#  if not c.nil?
#    total = total + c
#    print total,
#  end
#end
#puts sp.get_modem_params()

#sp.each_char do |line|
#  puts line
#end