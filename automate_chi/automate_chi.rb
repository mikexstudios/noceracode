require 'au3' # make sure the AutoItX3.dll is in the same directory
#require 'ruby-debug'
#include AutoItX3 # useful if you don't want to always use AutoItX3:: before everything
require 'logger'
$log = Logger.new('C:\Users\Electrochemistry\Dropbox\Electrochemistry\Mike\07-26-2011\tafel5\tafel_cp.log')
$log.level = Logger::DEBUG

#TO THINK: Is there an easy way to set the path of saved files? The current path is
#being set in the cfg file, but the format looks ugly to touch. Need to figure out
#how to modify that file.

#Other constants
NETBOOK_SCREEN = [1040, 586] #px
DATA_LIST_WINDOW_TIMEOUT = 5 #sec


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

class EchemSoftware
  def initialize
    $log.debug 'Initializing echem program...'
    #AutoItX3.block_input = true
    
    #Check if another instance of the software is running. If so, we cannot start
    #ours.
    raise LoadError, 'Software already running!' if AutoItX3::Window.exists?('Electrochemical')

    @main_pid = AutoItX3.run('chi760d.exe')
    #Set title matching criterion looser: 2 = Match any substring in the title.
    AutoItX3.set_option('WinTitleMatchMode', 2)
    
    #Check for Link Failed window. If exists, quit software and raise error.
    #TODO: Can combine both wait and exists into one line since wait returns the
    #      handle to the window.
    AutoItX3::Window.wait('Error', '', 2) #wait for 2 sec so that we don't miss the Error window
    if AutoItX3::Window.exists?('Error')
      $log.warn 'Error: Link failed window exists. Closing it...'
      AutoItX3.send_keys('{ENTER}')
      #AutoItX3.send_keys('!fx') # file -> exit
      #raise LoadError, 'Potentiostat not turned on.'
    end
    
    #Wait for main window to exist
    #NOTE: We don't check for the full window title because during Errors, the window
    #      title actually changes! The only common part is 'Electrochemical'.
    AutoItX3::Window.wait('Electrochemical')
    @main_window = AutoItX3::Window.new('Electrochemical')
    @main_window.activate #sets focus to window
    
    # NORMALIZE WINDOW SIZE
    #We want to set the main window to a specific size so that our pixel matching
    #code is consistent across computers.
    $log.debug 'Normalizing window size...'
    @main_window.move(0, 0, NETBOOK_SCREEN.first, NETBOOK_SCREEN.last)
    #Maximize the child window
    AutoItX3.send_keys('!-x') # ALT+- accesses child window options. Then x to max.

    #TODO: Check program version and error if not correct version.
  end
  
  def kill
    $log.debug 'Killing echem software...'
    AutoItX3.close_process(@main_pid)
    AutoItX3.wait_for_process_close(@main_pid)
    AutoItX3.block_input = false
  end

  def setup_chronopotentiometry(cathodic_current, anodic_current, high_e, low_e,
                                cathodic_time, anodic_time, initial_polarity, 
                                data_storage_interval)
    $log.debug 'Setting up chronopotentiometry experiment...'

    @main_window.activate #sets focus to window
    AutoItX3.send_keys('!st') #open up the system -> techniques window
    AutoItX3::Window.wait('Electrochemical Techniques')

    #Single left click the chronopotentiometry item (at relative coordinates 55, 321)
    techniques = AutoItX3::Control.new('Electrochemical Techniques', '', 1000)
    techniques.click('left', 1, 55, 334)
    techniques.send_keys('{ENTER}') #OK button
    
    AutoItX3::Window.wait('Chronopotentiometry Parameters')
    parameters = AutoItX3::Window.new('Chronopotentiometry Parameters')
    # the nice thing is that each field in the dialog box is ALT accessible
    AutoItX3.send_keys('!C') #Cathodic Current (A)
    AutoItX3.send_keys(cathodic_current.to_s)
    AutoItX3.send_keys('!A') #Anodic Current (A)
    AutoItX3.send_keys(anodic_current.to_s)
    AutoItX3.send_keys('!H') #High E Limit (V)
    AutoItX3.send_keys(high_e.to_s)
    AutoItX3.send_keys('!L') #Low E Limit (V)
    AutoItX3.send_keys(low_e.to_s)
    AutoItX3.send_keys('!T') #Cathodic Time (sec)
    AutoItX3.send_keys(cathodic_time.to_s)
    AutoItX3.send_keys('!m') #Anodic Time (sec)
    AutoItX3.send_keys(anodic_time.to_s)
    AutoItX3.send_keys('!I') #Initial Polarity
    AutoItX3.send_keys('a')
    AutoItX3.send_keys('!D') #Data Storage Interval (sec)
    AutoItX3.send_keys(data_storage_interval.to_s)
    AutoItX3.send_keys('!e') #Set Current Switching Priority to Time
    AutoItX3.send_keys('{ENTER}') #OK button
  end

  def setup_amperometric_it_curve(init_e, sample_interval, run_time, quiet_time,
                                  scales_during_run, sensitivity)
    $log.debug 'Setting up amperometric i-t curve experiment...'

    @main_window.activate #sets focus to window
    AutoItX3.send_keys('!st') #open up the system -> techniques window
    AutoItX3::Window.wait('Electrochemical Techniques')

    #Single left click the chronopotentiometry item (at relative coordinates 55, 321)
    techniques = AutoItX3::Control.new('Electrochemical Techniques', '', 1000)
    techniques.click('left', 1, 55, 177)
    techniques.send_keys('{ENTER}') #OK button
    
    AutoItX3::Window.wait('Amperometric i-t Curve Parameters')
    parameters = AutoItX3::Window.new('Amperometric i-t Curve Parameters')
    # the nice thing is that each field in the dialog box is ALT accessible
    AutoItX3.send_keys('!I') #Init E (V)
    AutoItX3.send_keys(init_e.to_s)
    AutoItX3.send_keys('!a') #Sample Interval (sec)
    AutoItX3.send_keys(sample_interval.to_s)
    AutoItX3.send_keys('!T') #Run Time (sec)
    AutoItX3.send_keys(run_time.to_s)
    AutoItX3.send_keys('!Q') #Quiet Time (sec)
    AutoItX3.send_keys(quiet_time.to_s)
    AutoItX3.send_keys('!d') #Scales during Run
    AutoItX3.send_keys(scales_during_run.to_s)
    AutoItX3.send_keys('!S') #Sensitivity (A/V)
    # Since we can't enter in the value directly, we first need to normalize the
    # position. We normalize to 1.e-001 by pressing up 12 times.
    (1..12).each { |i| AutoItX3.send_keys('{UP}') }
    # We note that if user selects 1.e-001, then we don't press any down arrow.
    # For 1.e-002, we press down once. For 1.e-012, we press down 11 times. Thus,
    # we pull out the power part using log10. Then convert to a positive integer
    # and subtract one.
    down_arrows = (Math.log10(sensitivity).to_i * -1) - 1
    (1..down_arrows).each { |i| AutoItX3.send_keys('{DOWN}') }
    AutoItX3.send_keys('{ENTER}') #OK button
  end

  def run(check_interval = 10, max_runtime = nil)
    $log.debug 'Running experiment...'
    @main_window.activate
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
    
    #TODO: Don't use a counter for time. Instead, use the computer's clock.
    total_runtime = 0 #sec, we keep track of how long the expt has run
    while true
      sleep(check_interval)
      total_runtime += check_interval
    
      #Check if program has crashed.
      if @main_window.hung?
        $log.error 'Detected main window hung.'
        raise RuntimeError, 'Software has crashed! Please restart experiment.'
      end
    
      #Check if we have an Error window.
      if AutoItX3::Window.exists?('Error')
        $log.error 'Detected Error window (probably Link Failed).'
        raise RuntimeError, 'Software has an error! Please restart experiment.'
      end
    
      #Check if experiment has completed with the menu method.
      #TODO: Implement the pixel detection method.
      AutoItX3.send_keys('!vl') #view -> data listing
      #Wait for some timeout time so that we don't accidentally miss the window.
      #NOTE: This will add to our status_check_interval...
      if AutoItX3::Window.wait('Data List', '', DATA_LIST_WINDOW_TIMEOUT)
        $log.info 'Data List window found! Assuming experiment has ended.'
        datalist_window = AutoItX3::Window.new('Data List')
        #Close the window
        datalist_window.close
        #Make sure that window does not exist anymore
        datalist_window.wait_close
    
        #Experiment has completed!
        break
      end
      total_runtime += DATA_LIST_WINDOW_TIMEOUT
    
      #Check if our total runtime is grossly above the expected runtime. If so, 
      #we can assume that the experiment is frozen or crashed and end the experiment.
      if max_runtime != nil and total_runtime >= max_runtime
        $log.error 'Exceeded maximum runtime. Software may have crashed.'
        raise RuntimeError, 'Exceeded maximum runtime! Software may have crashed!'
      end
    
      print '.' #for progress
	  $log.debug '.'
    end
  end

  def save_as(filename)
    $log.debug 'Saving as...'

    begin
      @main_window.activate
      AutoItX3.send_keys('!fa') #file -> save as
      AutoItX3::Window.wait('Save As')
      saveas_window = AutoItX3::Window.new('Save As')
      if not saveas_window.wait_active(timeout = 60) 
        $log.error 'Save As window not found.'
        raise RuntimeError, 'Save As window not found!'
      end
    rescue RuntimeError
      $log.info 'Retrying Save As...'
      AutoItX3.send_keys('{ESC}{ESC}')
      sleep('60') #sec
      retry
    end
    
    #The following does not work:
    ##Focus on the filename box
    #saveas_filename = AutoItX3::Control.new('Save As', '', 'Edit1')
    #saveas_filename.focus
    
    #We don't use the control's send keys because of errors, instead we just use
    #standard keyboard input.
    AutoItX3.msleep(2000) #2 sec, need some extra time to give right focus on edit field
    AutoItX3.send_keys(filename)
    AutoItX3.send_keys('{ENTER}')
    sleep(2) #sec, just to make sure file has saved
  end

  def close
    $log.debug 'Closing program...'

    # close gets us back to a clean slate again.
    AutoItX3.send_keys('!fc') #file -> close
  end
end

#TODO: Create new expt (file -> new) and expand window again.
