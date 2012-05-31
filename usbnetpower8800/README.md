To get the script working on Windows
====================================

* I don't know about 64-bit support. It's better to just use 32-bit Windows, 
  I think.

* Tested on 32-bit Windows 7.

1. Dev-kit for ruby must be installed.

2. gem install libusb
   (According to https://github.com/larskanis/libusb, the gem automatically
    installs libusb-1.0.0.dll for Windows, which is pretty awesome. Indeed,
    the gem places that dll in the gem's folder. Another way to obtain this
    dll is to download the nighly binaries from 
    http://www.libusb.org/wiki/windows_backend#LatestBinarySnapshots. Then,
    place the .dll in the gem's folder.)

3. Replace existing USBNetPower8800's driver (ser2pl (v.3.3.11.152)) with 
   one that can communicate with libusb-1.0 using Zadig
   (http://sourceforge.net/apps/mediawiki/libwdi/index.php?title=Main_Page).

   Essentially, run Zadig (get >= v2 to get presigned drivers). If the USB Net
   Power 8800's usb driver was already installed, you need to check 'List All
   Devices' to show it.

   Select the device, make sure the final driver is WinUSB (which works with
   libusb-1.0), and hit 'Reinstall Driver' button.

   Here's a nice guide: 
   http://sourceforge.net/apps/mediawiki/libwdi/index.php?title=Zadig2

(If #3 was not done correctly, then you will receive
 LIBUSB::ERROR_NOT_SUPPORTED error in ruby.)
