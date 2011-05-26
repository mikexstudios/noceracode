require 'au3' # make sure the AutoItX3.dll is in the same directory
require 'ruby-debug'
#include AutoItX3 # useful if you don't want to always use AutoItX3:: before everything

#Experiment variables
anodic_current = 1e-3 #A
anodic_time = 200 #sec
potential_range = [0, 2] #low, high V

#Other constants
NETBOOK_SCREEN = [1040, 586] #px


#Monkey patch Window class to check for non-responsive (hung) windows:
class AutoItX3::Window
  # Test for program responsiveness.
  def hung?
    # We need to directly hook into IsHungAppWindow using the Win32API library.
    # IsHungAppWindow accepts an hWnd (a long) and outputs a bool (which we
    # model as a long).
    isHungAppWindow = Win32::API.new('IsHungAppWindow', 'P', 'I', 'user32.dll')
    return isHungAppWindow.call(handle) == 1
  end
end

AutoItX3.run('chi760d.exe')

#Check for Link Failed window. If exists, quit software and raise error.
AutoItX3::Window.wait('Error', '', 2) #wait for 2 sec so that we don't miss the Error window
if AutoItX3::Window.exists?('Error')
  AutoItX3.send_keys('{ENTER}')
  AutoItX3.send_keys('!fx') # file -> exit
  raise "Potentiostat not turned on."
end

#Wait for main window to exist
AutoItX3::Window.wait('CHI760D Electrochemical Workstation')
main_window = AutoItX3::Window.new('CHI760D Electrochemical Workstation')

# NORMALIZE WINDOW SIZE
#We want to set the main window to a specific size so that our pixel matching
#code is consistent across computers.
main_window.move(0, 0, NETBOOK_SCREEN.first, NETBOOK_SCREEN.last)
#Maximize the child window
AutoItX3.send_keys('!-x') # ALT+- accesses child window options. Then x to max.


AutoItX3.send_keys('!st') #open up the system -> techniques window
AutoItX3::Window.wait('Electrochemical Techniques')
#Single left click the chronopotentiometry item (at relative coordinates 55, 321)
techniques = AutoItX3::Control.new('Electrochemical Techniques', '', 1000)
techniques.click('left', 1, 55, 321)
techniques.send_keys('{ENTER}') #OK button

AutoItX3::Window.wait('Chronopotentiometry Parameters')
parameters = AutoItX3::Window.new('Chronopotentiometry Parameters')
# the nice thing is that each field in the dialog box is ALT accessible
AutoItX3.send_keys('!C') #Cathodic Current (A)
AutoItX3.send_keys('0')
AutoItX3.send_keys('!A') #Anodic Current (A)
AutoItX3.send_keys(anodic_current.to_s)
AutoItX3.send_keys('!H') #High E Limit (V)
AutoItX3.send_keys(potential_range.last.to_s)
AutoItX3.send_keys('!L') #Low E Limit (V)
AutoItX3.send_keys(potential_range.first.to_s)
AutoItX3.send_keys('!T') #Cathodic Time (sec)
AutoItX3.send_keys('1')
AutoItX3.send_keys('!m') #Anodic Time (sec)
AutoItX3.send_keys(anodic_time.to_s)
AutoItX3.send_keys('!I') #Initial Polarity
AutoItX3.send_keys('a')
AutoItX3.send_keys('!D') #Data Storage Interval (sec)
AutoItX3.send_keys('1')
AutoItX3.send_keys('!e') #Set Current Switching Priority to Time
AutoItX3.send_keys('{ENTER}') #OK button

#Now run the experiment
main_window.activate
AutoItX3.send_keys('!cr') #control -> run experiment

#Check the status of the program. We check for both program crashing:
#1. If the program is 'hung' for freezing.
#2. If there is an 'Error' popup window (ie. Link Failed).
#and if the experiment has ended yet:
#3. If a pixel near the time component is changing. (This may depend on screen 
#   size, unfortunately.)
#4. If certain menu items are accessible since they are not accessible if the
#   experiment has not completed yet.
#If the experiment has ended, do a sanity check to see if the experiment has ended
#before our expected time.


if main_window.hung?
    puts 'hung'
else
    puts 'not hung'
end
