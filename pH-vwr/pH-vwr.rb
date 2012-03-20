#!/usr/bin/env ruby
# Class to control VWR's sympHony pH meter through serial port

require 'serialport'

# pH meter MUST have the following settings (set using Menu):
#  * Baud rate = 9600
#  * Output = Comp (not printer)
class PHVWR
  # port_num integer Either /dev/ttySN or COM(N+1) where N is the port_num
  #                  So to specify COM1 in Windows, use port_num = 0.
  def initialize(port_num)
    @port_num = port_num
    @pH = nil
    @temp = nil
  end

  def measure
    #When we send GETMEAS, we get back a string that looks like this:
    #> 2,C00923,2.22,10,01-23-2083 07:43:45,8.01,pH,-62.7,mV,23.2,C,60,19670
    #| not sure     |       datetime       |  pH   | raw E  | temp | not sure |
    #These fields seem fixed so we can simply split by ',' and index by number.
    line = self.send('GETMEAS')
    line = line.split(',')
    fail if line[6] != 'pH'
    fail if line[10] != 'C'

    @pH = line[5].to_f
    @temp = line[9].to_f
  end

  private

  # We make a separate method for open since we need to open and close the
  # serialport on each command or else it will block the timeout.
  def open
    @sp = SerialPort.new(@port_num, :baudrate => 9600, :databits => 8, 
                        :stopbits => 1, :parity => SerialPort::NONE)
    #We need to set timeouts for when serialport expects data from device
    #but doesn't actually receive it. Thus, it will hang unless a timeout
    #is set. However, this timeout does not actually seem to work. Thus, 
    #we will get around this problem by re-initializing the serial port
    #each time we use it and manually detect any hangs.
    @sp.read_timeout = 100 #not perfect, but good enough for GETMEAS
    @sp.write_timeout = 1
  end

  def close
    @sp.close
  end
   
  # A wrapper to open serialport, send command with \r\n, get data, and close.
  # NOTE: Can only read one line! So only works for short return buffers such
  #       as getting pH value.
  def send(cmd)
    self.open
    @sp.write "%s\r\n" % cmd
    line = @sp.readline
    self.close

    return line
  end
end
