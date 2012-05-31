Protocol for VWR's sympHony pH meter
====================================

On the meter, set through the menu of the device:

  * Baud rate = 9600
  * Output = Comp (not printer)

Then one can use SerialMon with the following settings:

  * Baudrate: 9600
  * Data bits: 8
  * Parity: None
  * Stop bits: 1

Issue the HELP command (with trailing CR+LF) to get back:

    GETCAL    GETCAL <type>, where type=PH, ISE, ORP, COND, or DO
    GETLOG    GETLOG <log>, where log= CALPH, CALISE, CALORP, CALCOND, CALDO or MEAS
    GETMEAS   Displays the current measurement
    GETMENU   GETMENU <name>
    HELP ?    Display help for remote control mode 
    KEY K     KEY <key> Meas Cal Up Down Setup loG stiR decPt poWer Line
    METHOD    METHOD
    SETMENU   SETMENU name value
    SYSTEM    returns system information


Sidenote
========

The interesting thing is that the Trendnet USB to Serial connector and the 
USB Net Power 8800 both use the same chip to convert from USB to Serial. 
Thus, when modifying the USB driver for the Net Power 8800 device, the Trendnet
driver will also seemingly be changed. Rollback the device driver on the 
Trendnet device only.

TODO: It may be possible to simply control the Net Power 8800 through serial.
That would elminate additional layer of USB complexity.
