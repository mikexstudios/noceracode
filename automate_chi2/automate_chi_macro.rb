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
  attr_accessor :macro

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
    
    #Set a blank macro
    @macro = ''
  end
  
  def kill
    $log.debug 'Killing echem software...'
    AutoItX3.close_process(@main_pid)
    AutoItX3.wait_for_process_close(@main_pid)
    AutoItX3.block_input = false
  end

  # Given a macro string, enters it into the Macro Command... window and 
  # runs it.
  def execute_macro(check_interval = 10, max_runtime = nil,
                    is_information_expected = false)
    $log.debug 'Executing macro...'

    @main_window.activate #sets focus to window
    AutoItX3.send_keys('!cm') #open up the control -> Macro Command...
    AutoItX3::Window.wait('Macro Command')

    AutoItX3.send_keys('!E') #Get into the text box
    AutoItX3.send_keys(@macro)
    sleep(2)
    AutoItX3.send_keys('!M') #Run Macro
    
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
  
  def setup_save_folder(path)
    $log.debug 'Setting save folder: %s' % path
    @macro += "folder: %s\n" % path
  end

  def setup_save_filename(filename, save_text = true)
    $log.debug 'Setting save filename: %s' % filename
    @macro += "fileoverride\n"
    @macro += "save = %s\n" % filename
    if save_text
      @macro += "tsave = %s\n" % filename
    end
  end

  def setup_charge_abort(charge)
    $log.debug 'Setting experiment abort when charge greater than: %g' % charge
    @macro += "abortq = %g\n" % charge
  end

  def setup_manual_ir_compensation(resistance)
    $log.debug 'Setting manual iR compensation: %g' % resistance

    @macro += "mir = %g\n" % resistance
    @macro += "ircompon\n" #to turn off, use: ircompoff
  end

  def setup_amperometric_it_curve(params)
    $log.debug 'Setting up amperometric i-t curve experiment...'
    params = { :init_e => 0.0, 
               :sample_interval => 0.1, 
               :run_time => 400,
               :quiet_time => 0,
               #:scales_during_run => 3,
               :sensitivity => 1.0e-6,
             }.merge(params)
    $log.info params

    @macro += "tech = i-t\n"
    @macro += "ei = %g\n" % params[:init_e]
    @macro += "si = %g\n" % params[:sample_interval]
    @macro += "st = %g\n" % params[:run_time]
    @macro += "qt = %g\n" % params[:quiet_time]
    @macro += "sens = %g\n" % params[:sensitivity]
    @macro += "run\n"
  end

  def setup_cyclic_voltammetry(params)
    $log.debug 'Setting up cyclic voltammetry experiment...'
    params = { :init_e => 0, 
               :high_e => 0,
               :low_e => 0,
               :final_e => 0,
               :initial_scan_polarity => :negative,
               :scan_rate => 0.1,
               :sweep_segments => 2,
               :sample_interval => 0.001,
               :quiet_time => 2,
               :sensitivity => 1.0e-3,
             }.merge(params)
    $log.info params

    @macro += "tech = cv\n"
    if params[:init_e] == :ocp
      @macro += "eio\n" 
    else
      @macro += "ei = %g\n" % params[:init_e]
    end
    @macro += "eh = %g\n" % params[:high_e]
    @macro += "el = %g\n" % params[:low_e]
    #@macro += "ef = %g\n" % params[:init_e]
    pn = 'p' if params[:initial_scan_polarity] == :positive
    pn = 'n' if params[:initial_scan_polarity] == :negative
    @macro += "pn = %s\n" % pn
    @macro += "v = %g\n" % params[:scan_rate]
    @macro += "cl = %i\n" % params[:sweep_segments]
    @macro += "si = %g\n" % params[:sample_interval]
    @macro += "qt = %g\n" % params[:quiet_time]
    @macro += "sens = %g\n" % params[:sensitivity]
    @macro += "run\n"
  end

  def close
    $log.debug 'Closing program...'

    # close gets us back to a clean slate again.
    AutoItX3.send_keys('!fc') #file -> close
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

  # Use this method to determine the IR compensation needed for setting
  # manual IR compensation.
  def automatic_ir_compensation(params)
    $log.debug 'Setting and testing automatic iR compensation...'
    params = { :test_e => 0.0, 
               :overshoot => 2, 
               :step_amplitude => 0.05,
               :comp_level => 100,
             }.merge(params)
    $log.info params

    @main_window.activate #sets focus to window
    AutoItX3.send_keys('!ci') #open up the control -> iR Compensation window
    AutoItX3::Window.wait('iR Compensation')

    AutoItX3.send_keys('!w') #Always enable iR Comp
    AutoItX3.send_keys('!A') #Set iR Comp Mode to Automatic
    AutoItX3.send_keys('!i') #Check iR Compensation for Next Run box

    AutoItX3.send_keys('!E') #Test E (V)
    AutoItX3.send_keys(params[:test_e].to_s)
    AutoItX3.send_keys('!S') #Step Amplitude (V)
    AutoItX3.send_keys(params[:step_amplitude].to_s)
    AutoItX3.send_keys('!L') #Comp Level (%)
    AutoItX3.send_keys(params[:comp_level].to_s)
    AutoItX3.send_keys('!v') #Overshoot (%)
    AutoItX3.send_keys(params[:overshoot].to_s)

    AutoItX3.send_keys('!T') #Test button

    tries = 0
    begin
      #Now we have to wait until values appear in the iR Comp Test Results area.
      sleep(18) #sec
  
      #Now extract the values
      resistance_control = AutoItX3::Control.new('iR Compensation', '', 'Edit1')
      rc_constant_control = AutoItX3::Control.new('iR Compensation', '', 'Edit2')
      comp_level_control = AutoItX3::Control.new('iR Compensation', '', 'Edit3')
      uncomp_r_control = AutoItX3::Control.new('iR Compensation', '', 'Edit4')

      if resistance_control.text.strip.empty? and rc_constant_control.text.strip.empty?
        $log.error 'iR Comp Test Results are empty!'
        raise RuntimeError, 'iR Comp Test Results are empty!'
      end
    rescue RuntimeError, AutoItX3::Au3Error #It could be that Edit1 can't be read yet
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

    comp_output =  {'resistance' => resistance, 
            'rc_constant' => rc_constant,
            'comp_level' => comp_level,
            'uncomp_r' => uncomp_r}
    $log.info comp_output
    return comp_output
  end

end

require 'automate_helpers.rb'
