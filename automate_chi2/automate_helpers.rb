# Put helpers for actually running experiments here.

def run_ait
  begin
    $log.info 'tafel_ait: %s' % @save_filename
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
    sleep(60) #1 minutes to let instrument rest
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
    $log.info 'tafel_ait: %s' % @save_filename
    es = EchemSoftware.new
    es.setup_save_folder(@save_path)
    es.setup_manual_ir_compensation(@ir_comp)
    es.setup_amperometric_it_curve(:init_e => @init_e, 
      :sample_interval => @sample_interval, 
      :run_time => @sample_time.call(@init_e), 
      :quiet_time => 0,
      :sensitivity => @sensitivity.call(@init_e)) 
    es.setup_save_filename(@save_filename)
	
    #When our runtime exceeds the maximum runtime given below, we assume the experi
    #has crashed and exit from loop.
    @status_check_interval = (@sample_time.call(@init_e) + 5) / 2 #sec
    @status_max_runtime = @sample_time.call(@init_e) + 10 #sec
    es.execute_macro(@status_check_interval, @status_max_runtime)
  rescue RuntimeError
    $log.error 'RuntimeError: Retrying experiment...'
    $log.info 'Killing program and sleeping for a bit...'
    #Getting here means that the software has crashed. So let's try to restart
    #it again.
    es.kill
    sleep(60) #1 minutes to let instrument rest
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
    sleep(60) #1 minutes to let instrument rest
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
