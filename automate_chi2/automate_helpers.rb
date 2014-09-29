# Put helpers for actually running experiments here.

def run_ait
  begin
    $log.info 'ait: %s' % @save_filename
    es = EchemSoftware.new
    es.set_save_path(@save_path)
    es.setup_amperometric_it_curve(@init_e, @sample_interval, @sample_time.call(@init_e), 
                                   0, 3, @sensitivity.call(@init_e)) 

    #Another quirk with the software is that iR comp must be called after RDE
    #it seems or else iR comp won't actually be enabled.
    es.setup_manual_ir_compensation(@ir_comp)
	
    #When our runtime exceeds the maximum runtime given below, we assume the experi
    #has crashed and exit from loop.
    @status_check_interval = (@sample_time.call(@init_e) + 5) / 2 #sec
    @status_max_runtime = @sample_time.call(@init_e) + 10 #sec
    es.run(@status_check_interval, @status_max_runtime)

    es.save_as(@save_filename)
  rescue RuntimeError
    $log.error 'RuntimeError: Retrying experiment...'
    $log.info 'Killing program and sleeping for a bit...'
    #Getting here means that the software has crashed. So let's try to restart
    #it again.
    es.kill
    sleep(20) #1 minutes to let instrument rest
    retry
  ensure
    if es #when we have errors, es is automatically GC'ed and set to nil.
      $log.info 'Killing program through ensure...'
      es.kill
      es = nil
    end
  end
  $log.info
  $log.info
  $log_file.flush #since .sync doesn't work for some reason
  print '.'
end

def run_ait_macro
  begin
    $log.info 'ait: %s' % @save_filename
    es = EchemSoftware.new
    es.setup_save_folder(@save_path)
    es.setup_manual_ir_compensation(@ir_comp)
    es.setup_amperometric_it_curve(:init_e => @init_e, 
      :sample_interval => @sample_interval, 
      :run_time => @run_time, 
      :quiet_time => 0,
      :sensitivity => @sensitivity) 
    es.setup_save_filename(@save_filename)
	
    #When our runtime exceeds the maximum runtime given below, we assume the experi
    #has crashed and exit from loop.
    @status_check_interval = (@run_time + 5) / 2 #sec
    @status_max_runtime = @run_time + 10 #sec
    es.execute_macro(@status_check_interval, @status_max_runtime)
  rescue RuntimeError
    $log.error 'RuntimeError: Retrying experiment...'
    $log.info 'Killing program and sleeping for a bit...'
    #Getting here means that the software has crashed. So let's try to restart
    #it again.
    es.kill
    sleep(20) #1 minutes to let instrument rest
    retry
  ensure
    if es #when we have errors, es is automatically GC'ed and set to nil.
      $log.info 'Killing program through ensure...'
      es.kill
      es = nil
    end
  end
  $log.info
  $log.info
  $log_file.flush #since .sync doesn't work for some reason
  print '.'
end

def run_dep_ait_macro
  begin
    $log.info 'dep_ait: %s' % @save_filename
    es = EchemSoftware.new

    #Starting from blank electrode, get iR compensation if none specified.
    if @ir_comp == :auto or @ir_comp.nil?
      ocp = es.get_open_circuit_potential
      @ir_comp = es.automatic_ir_compensation(:test_e => ocp)['resistance']
    end

    es.setup_save_folder(@save_path)
    es.setup_manual_ir_compensation(@ir_comp)
    es.setup_charge_abort(@total_charge)
    es.setup_amperometric_it_curve(:init_e => @init_e, 
      :sample_interval => @sample_interval, 
      :run_time => @status_max_runtime - 10, 
      :quiet_time => 0,
      :sensitivity => @sensitivity) 
    es.setup_save_filename(@save_filename)
	
    #When our runtime exceeds the maximum runtime given below, we assume the experi
    #has crashed and exit from loop.
    es.execute_macro(@status_check_interval, @status_max_runtime)
  rescue RuntimeError
    $log.error 'RuntimeError: Retrying experiment...'
    $log.info 'Killing program and sleeping for a bit...'
    #Getting here means that the software has crashed. So let's try to restart
    #it again.
    es.kill
    sleep(20) #1 minutes to let instrument rest
    retry
  ensure
    if es #when we have errors, es is automatically GC'ed and set to nil.
      $log.info 'Killing program through ensure...'
      es.kill
      es = nil
    end
  end
  $log.info
  $log.info
  $log_file.flush #since .sync doesn't work for some reason
  print '.'
end


def run_cv_macro
  begin
    $log.info 'cv: %s' % @save_filename
    es = EchemSoftware.new

    #Starting from blank electrode, get iR compensation if none specified.
    if @ir_comp == :auto or @ir_comp.nil?
      ocp = es.get_open_circuit_potential
      @ir_comp = es.automatic_ir_compensation(:test_e => ocp)['resistance']
    end

    es.setup_save_folder(@save_path)
    es.setup_manual_ir_compensation(@ir_comp)
    es.setup_cyclic_voltammetry(:init_e => @init_e, 
      :high_e => @high_e,
      :low_e => @low_e,
      :initial_scan_polarity => @initial_scan_polarity, 
      :scan_rate => @scan_rate,
      :sweep_segments => @sweep_segments,
      :sample_interval => @sample_interval,
      :quiet_time => 0,
      :sensitivity => @sensitivity) 
    es.setup_save_filename(@save_filename)

    #Compute an approximate runtime from scan rate and potential range.
    #We assume that the first scan (from :init_e to :high_e) is from :low_e instead.
    run_time = (@high_e - @low_e).abs / @scan_rate * @sweep_segments
    @status_check_interval = (run_time + 5) / 2 #sec
    @status_max_runtime = run_time + 10 #sec
    $log.debug '@status_check_interval: %i' % @status_check_interval
    $log.debug '@status_max_runtime: %i' % @status_max_runtime
  
    #When our runtime exceeds the maximum runtime given below, we assume the experi
    #has crashed and exit from loop.
    es.execute_macro(@status_check_interval, @status_max_runtime)
  rescue RuntimeError
    $log.error 'RuntimeError: Retrying experiment...'
    $log.info 'Killing program and sleeping for a bit...'
    #Getting here means that the software has crashed. So let's try to restart
    #it again.
    es.kill
    sleep(20) #1 minutes to let instrument rest
    retry
  ensure
    if es #when we have errors, es is automatically GC'ed and set to nil.
      $log.info 'Killing program through ensure...'
      es.kill
      es = nil
    end
  end
  $log.info
  $log.info
  $log_file.flush #since .sync doesn't work for some reason
  print '.'
end

def run_be_macro
  begin
    $log.info 'be: %s' % @save_filename
    es = EchemSoftware.new
    es.setup_save_folder(@save_path)
    es.setup_manual_ir_compensation(@ir_comp)
    es.setup_bulk_electrolysis(:electrolysis_e => @electrolysis_e, 
      :run_time => @run_time, 
      :sample_interval => @sample_interval, 
      :sensitivity => :auto) 
    es.setup_save_filename(@save_filename)
	
    #When our runtime exceeds the maximum runtime given below, we assume the experi
    #has crashed and exit from loop.
    @status_check_interval = (@run_time + 5) / 2 #sec
    @status_max_runtime = @run_time + 10 #sec
    es.execute_macro(@status_check_interval, @status_max_runtime)
  rescue RuntimeError
    $log.error 'RuntimeError: Retrying experiment...'
    $log.info 'Killing program and sleeping for a bit...'
    #Getting here means that the software has crashed. So let's try to restart
    #it again.
    es.kill
    sleep(20) #1 minutes to let instrument rest
    retry
  ensure
    if es #when we have errors, es is automatically GC'ed and set to nil.
      $log.info 'Killing program through ensure...'
      es.kill
      es = nil
    end
  end
  $log.info
  $log.info
  $log_file.flush #since .sync doesn't work for some reason
  print '.'
end


def run_capacitance_macro
  begin
    $log.info 'cv: %s' % @save_filename
    es = EchemSoftware.new

    #Starting from blank electrode, get iR compensation if none specified.
    if @ir_comp == :auto or @ir_comp.nil?
      ocp = es.get_open_circuit_potential
      @ir_comp = es.automatic_ir_compensation(:test_e => ocp)['resistance']
    end

    es.setup_save_folder(@save_path)
    es.setup_manual_ir_compensation(@ir_comp)

    #Hold first point for a small amount of time. Don't save.
    es.setup_cyclic_voltammetry(:init_e => @init_e, 
      :high_e => @init_e + 0.011,
      :low_e => @low_e,
      :initial_scan_polarity => @initial_scan_polarity, 
      :scan_rate => 0.001,
      :sweep_segments => 1,
      :sample_interval => @sample_interval,
      :quiet_time => 0,
      :sensitivity => @sensitivity) 
    
    es.setup_cyclic_voltammetry(:init_e => @init_e, 
      :high_e => @high_e,
      :low_e => @low_e,
      :initial_scan_polarity => @initial_scan_polarity, 
      :scan_rate => @scan_rate,
      :sweep_segments => @sweep_segments,
      :sample_interval => @sample_interval,
      :quiet_time => 0,
      :sensitivity => @sensitivity) 
    es.setup_save_filename(@save_filename)

    #Compute an approximate runtime from scan rate and potential range.
    #We assume that the first scan (from :init_e to :high_e) is from :low_e instead.
    run_time = 12 + (@high_e - @low_e).abs / @scan_rate * @sweep_segments
    @status_check_interval = (run_time + 5) / 2 #sec
    @status_max_runtime = run_time + 10 #sec
    $log.debug '@status_check_interval: %i' % @status_check_interval
    $log.debug '@status_max_runtime: %i' % @status_max_runtime
  
    #When our runtime exceeds the maximum runtime given below, we assume the experi
    #has crashed and exit from loop.
    es.execute_macro(@status_check_interval, @status_max_runtime)
  rescue RuntimeError
    $log.error 'RuntimeError: Retrying experiment...'
    $log.info 'Killing program and sleeping for a bit...'
    #Getting here means that the software has crashed. So let's try to restart
    #it again.
    es.kill
    sleep(3) #1 minutes to let instrument rest
    retry
  ensure
    if es #when we have errors, es is automatically GC'ed and set to nil.
      $log.info 'Killing program through ensure...'
      es.kill
      es = nil
    end
  end
  $log.info
  $log.info
  $log_file.flush #since .sync doesn't work for some reason
  print '.'
end
