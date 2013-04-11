require 'au3' # make sure the AutoItX3.dll is in the same directory
require 'logger' 
#require 'ruby-debug'

# Check if $log_file has been given. If not, then use STDOUT.
$log = Logger.new($log_file || STDOUT)
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
    begin
      raise LoadError, 'Software already running!' if AutoItX3::Window.exists?('Electrochemical')
    rescue Win32::API::LoadLibraryError
      raise LoadError, 'AutoItX3.dll does not exist!'
    end

    @main_pid = AutoItX3.run('chi760d.exe')
    raise LoadError, 'CHI Software not found in same directory!' if @main_pid.nil?
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

  # The strategy is to use the `folder:` macro command to set the save path.
  def set_save_path(path)
    @main_window.activate #sets focus to window
    AutoItX3.send_keys('!cm') #open up the control -> Macro Command...
    AutoItX3::Window.wait('Macro Command')

    AutoItX3.send_keys('!E') #Get into the text box
    AutoItX3.send_keys('folder: %s' % path)
    
    AutoItX3.send_keys('!M') #Run Macro
  end

  def setup_cyclic_voltammetry(params)
    $log.debug 'Setting up cyclic voltammetry experiment...'
    params = { :init_e => 0.0, 
               :high_e => 0.0, 
               :low_e => 0.0, 
               :final_e => 0.0,
               :initial_scan_polarity => 'negative', 
               :scan_rate => 0.1,
               :sweep_segments => 2, 
               :sample_interval => 0.001, 
               :sensitivity => 1.0e-6,
             }.merge(params)
    $log.info params

    @main_window.activate #sets focus to window
    #NOTE: We don't  need to open up the techniques window because upon clean
    #start, the default technique should be CV.
    AutoItX3.send_keys('!sp') #open up the system -> parameters
    
    AutoItX3::Window.wait('Cyclic Voltammetry Parameters')
    parameters = AutoItX3::Window.new('Cyclic Voltammetry Parameters')
    AutoItX3.send_keys('!I') #Init E (V)
    AutoItX3.send_keys(params[:init_e].to_s)
    AutoItX3.send_keys('!H') #High E (V)
    AutoItX3.send_keys(params[:high_e].to_s)
    AutoItX3.send_keys('!L') #Low E (V)
    AutoItX3.send_keys(params[:low_e].to_s)
    #NOTE: On some systems, the final e may be greyed out. Thus, we need to 
    #enable Final E first through the convoluted process of checking Auto Sens,
    #tabbing to 'Enable Final E', then disabling Auto Sens.
    AutoItX3.send_keys('!A{TAB}{SPACE}!A') #Enable Final E
    AutoItX3.send_keys('!L{TAB}') #Final E (V)
    AutoItX3.send_keys(params[:final_e].to_s)

    AutoItX3.send_keys('!P') #Initial Scan Polarity
    # Since we can't enter in the value directly, we first need to normalize the
    # position. We normalize to the "Negative" value by pressing up a few times.
    3.times { AutoItX3.send_keys('{UP}') }
    if params[:initial_scan_polarity] == 'positive' then AutoItX3.send_keys('{DOWN}') end

    AutoItX3.send_keys('!R') #Scan Rate (V/s)
    AutoItX3.send_keys(params[:scan_rate].to_s)
    AutoItX3.send_keys('!w') #Sweep Segments
    AutoItX3.send_keys(params[:sweep_segments].to_s)
    AutoItX3.send_keys('!m') #Sample Interval (V)
    AutoItX3.send_keys(params[:sample_interval].to_s)

    AutoItX3.send_keys('!S') #Sensitivity (A/V)
    # Since we can't enter in the value directly, we first need to normalize the
    # position. We normalize to 1.e-001 by pressing up 12 times.
    12.times { AutoItX3.send_keys('{UP}') }
    # We note that if user selects 1.e-001, then we don't press any down arrow.
    # For 1.e-002, we press down once. For 1.e-012, we press down 11 times. Thus,
    # we pull out the power part using log10. Then convert to a positive integer
    # and subtract one.
    down_arrows = (Math.log10(params[:sensitivity]).to_i * -1) - 1
    down_arrows.times { AutoItX3.send_keys('{DOWN}') }

    AutoItX3.send_keys('{ENTER}') #OK button
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

  def get_open_circuit_potential
    $log.debug 'Getting open circuit potential...'
    @main_window.activate #sets focus to window

    AutoItX3.send_keys('!co') #open up the control -> Open Circuit Potential window
    AutoItX3::Window.wait('Open Circuit Potential Measurement')

    ocp_control = AutoItX3::Control.new('Open Circuit Potential Measurement', '', 'Edit1')
    ocp = ocp_control.text.to_f

    AutoItX3.send_keys('{ENTER}') #OK button
    return ocp
  end

  def setup_automatic_ir_compensation(test_e = 0.0, overshoot = 2, 
                                      step_amplitude = 0.05, comp_level = 100)
    $log.debug 'Setting and testing automatic iR compensation...'

    @main_window.activate #sets focus to window
    AutoItX3.send_keys('!ci') #open up the control -> iR Compensation window
    AutoItX3::Window.wait('iR Compensation')

    AutoItX3.send_keys('!w') #Always enable iR Comp
    AutoItX3.send_keys('!A') #Set iR Comp Mode to Automatic
    AutoItX3.send_keys('!i') #Check iR Compensation for Next Run box

    AutoItX3.send_keys('!E') #Test E (V)
    AutoItX3.send_keys(test_e.to_s)
    AutoItX3.send_keys('!S') #Step Amplitude (V)
    AutoItX3.send_keys(step_amplitude.to_s)
    AutoItX3.send_keys('!L') #Comp Level (%)
    AutoItX3.send_keys(comp_level.to_s)
    AutoItX3.send_keys('!v') #Overshoot (%)
    AutoItX3.send_keys(overshoot.to_s)

    AutoItX3.send_keys('!T') #Test button

    tries = 0
    begin
      #Now we have to wait until values appear in the iR Comp Test Results area.
      sleep(18) #sec
      #TODO: Have a retry loop checking for the iR comp values to appear
  
      #Now extract the values
      resistance_control = AutoItX3::Control.new('iR Compensation', '', 'Edit1')
      rc_constant_control = AutoItX3::Control.new('iR Compensation', '', 'Edit2')
      comp_level_control = AutoItX3::Control.new('iR Compensation', '', 'Edit3')
      uncomp_r_control = AutoItX3::Control.new('iR Compensation', '', 'Edit4')

      if resistance_control.text.strip.empty? and rc_constant_control.text.strip.empty?
        $log.error 'iR Comp Test Results are empty!'
        raise RuntimeError, 'iR Comp Test Results are empty!'
      end
    rescue RuntimeError
      tries += 1
      $log.info 'Retrying reading iR Comp Test Results...'
      retry if tries < 2
      #This RuntimeError should be caught by the running script (eg. it should
      #then kill the program and restart on this point).
      $log.error 'iR Comp Test Results are empty despite retries!'
      raise RuntimeError, 'iR Comp Test Results are empty despite retries!'
    end

    resistance = resistance_control.text.to_f
    rc_constant = rc_constant_control.text.to_f
    comp_level = comp_level_control.text.to_f
    uncomp_r = uncomp_r_control.text.to_f

    AutoItX3.send_keys('{ENTER}') #OK button to exit box

    return {'resistance' => resistance, 
            'rc_constant' => rc_constant,
            'comp_level' => comp_level,
            'uncomp_r' => uncomp_r}
  end

  def setup_manual_ir_compensation(resistance)
    $log.debug 'Setting manual iR compensation...'

    @main_window.activate #sets focus to window
    AutoItX3.send_keys('!ci') #open up the control -> iR Compensation window
    AutoItX3::Window.wait('iR Compensation')
    AutoItX3.send_keys('!w') #Always enable iR Comp
    AutoItX3.send_keys('!M') #Set iR Comp Mode to Manual
	sleep(0.25) #sec, let the next checkbox be enabled
    AutoItX3.send_keys('!i') #Check iR Compensation for Next Run box
    AutoItX3.send_keys('!R') #Resistance (ohm) under Manual Comp
    AutoItX3.send_keys(resistance.to_s)
    AutoItX3.send_keys('{ENTER}') #OK button
  end

  def setup_rotating_disk_electrode(rpm)
    $log.debug 'Setting rotating disk electrode...'

    @main_window.activate #sets focus to window
    AutoItX3.send_keys('!ck') #open up the control -> Rotating disk electrode
    AutoItX3::Window.wait('Rotating Disk Electrode Control')
    AutoItX3.send_keys('!S') #Get to Rotation Speed (rpm)
    AutoItX3.send_keys(rpm.to_s)
    #Rotate during deposition time should already be checked so we skip that
	AutoItX3.send_keys('!D') #Rotate during Deposition Time
	AutoItX3.send_keys('-=') #Force the checkbox
    AutoItX3.send_keys('!Q') #Rotate during Quiet Time
	AutoItX3.send_keys('-=') #Force the checkbox
    AutoItX3.send_keys('!R') #Rotate during Run
	AutoItX3.send_keys('-=') #Force the checkbox
    AutoItX3.send_keys('!b') #Rotate between Run
	AutoItX3.send_keys('-=') #Force the checkbox
    AutoItX3.send_keys('{ENTER}') #OK button
  end

  def run(check_interval = 10, max_runtime = nil, is_information_expected = false)
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
	  sleep(5)
	  
	  #Check if we have an Error window.
      if AutoItX3::Window.exists?('Error')
        $log.error 'Detected Error window (probably Link Failed).'
        raise RuntimeError, 'Software has an error! Please restart experiment.'
      end
	  
      sleep(check_interval-5)
      total_runtime += check_interval
    
      #Check if program has crashed.
      if @main_window.hung?
        $log.error 'Detected main window hung.'
        raise RuntimeError, 'Software has crashed! Please restart experiment.'
      end

      #If we are limiting by charge, the experiment will end when the Information
      #window appears. Thus, we will detect that instead.
      if is_information_expected
        if AutoItX3::Window.wait('Information', '', max_runtime)
          $log.info 'Information window found! Assuming experiment has ended.'
          information_window = AutoItX3::Window.new('Information')
          #Close the window
          information_window.close
          #Make sure that window does not exist anymore
          information_window.wait_close
    
          #Experiment has completed!
          break
        else
          $log.error 'Exceeded maximum runtime. Software may have crashed.'
          raise RuntimeError, 'Exceeded maximum runtime! Software may have crashed!'
        end
      else
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
  end

  def save_as(filename)
    $log.debug 'Saving as...'

    tries = 0
    begin
      @main_window.activate
      AutoItX3.send_keys('!fa') #file -> save as
      if not AutoItX3::Window.wait('Save As', '', timeout = 60) #seconds
        $log.error 'Save As window not found.'
        raise RuntimeError, 'Save As window not found!'
      end
      saveas_window = AutoItX3::Window.new('Save As')
    rescue RuntimeError
      tries += 1
      $log.info 'Retrying Save As...'
      AutoItX3.send_keys('{ESC}{ESC}')
      sleep(60) #sec
      retry if tries <= 3
      #This RuntimeError should be caught by the running script (eg. it should
      #then kill the program and restart on this point).
      $log.error 'Save As window not found despite retries.'
      raise RuntimeError, 'Save As window not found despite retries!'
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

  def abort_experiment_at_charge(charge)
    $log.debug 'Setting up Abort Experiment at Charge...'
    $log.info 'Charge: %E' % charge

    @main_window.activate #sets focus to window
    AutoItX3.send_keys('!cu') #open up the Control -> Run Status

    #Because there is no Alt accessible way of getting to the Charge edit
    #box, we need to tab our way there. First, get to Stir Between Runs;
    #then tab 6 times. Then uncheck Stir Between Runs.
    AutoItX3.send_keys('!S') #Stir Between Runs
    6.times { AutoItX3.send_keys('{TAB}') } 
    AutoItX3.send_keys(charge.to_s)
    AutoItX3.send_keys('!S') #Uncheck Stir Between Runs

    #Also, there is no way of using the keyboard to click the radio box for 
    #Charge (C). Thus, we use the mouse to do that.
    techniques = AutoItX3::Control.new('Run Status', '', 'Button17')
    techniques.click('left', 1, 36, 8)

    AutoItX3.send_keys('{ENTER}')
  end


end

#TODO: Create new expt (file -> new) and expand window again.

require 'automate_helpers.rb'