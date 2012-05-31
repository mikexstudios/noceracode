#!/usr/bin/env ruby
# Port of Paul Marks' python usbnetpower8800.py to ruby
# Original script: http://code.google.com/p/usbnetpower8800/

require 'libusb'

class USBNetPower8800
  attr_accessor :handle

  def initialize
    usb = LIBUSB::Context.new
    device = usb.devices(:idVendor => 0x067b, :idProduct => 0x2303).first
    raise IOError, 'USB Net Power 8800 not found!' if device.nil?
    @handle = device.open
    @handle.claim_interface(0)
  end

  def close
    @handle.release_interface(0)
  end

  # @return boolean If the power is currently switched on, returns true.
  def on?
    data_in = @handle.control_transfer(:bmRequestType => 0xc0, :bRequest => 0x01, 
                                      :wValue => 0x0081, :wIndex => 0x0000, 
                                      :dataIn => 0x01) #Set buffer size to 1 byte
    #data_in is returned as a hex in string, ie. "\xa0", we need to convert that
    #to a raw hex value.
    data_in = data_in.unpack('H*').first.hex
    return data_in == 0xa0
  end

  def on
    @handle.control_transfer(:bmRequestType => 0x40, :bRequest => 0x01, 
                             :wValue => 0x0001, :wIndex => 0xa0)
  end

  def off
    @handle.control_transfer(:bmRequestType => 0x40, :bRequest => 0x01, 
                             :wValue => 0x0001, :wIndex => 0x20)
  end

  def toggle
    if self.on? then self.off else self.on end
  end

end

