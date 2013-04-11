# Put helpers for actually running experiments here.

def run_ait
  begin
    $log.info 'tafel_ait: %s' % @save_filename
    es = EchemSoftware.new
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

    @save_filename  = @save_filename_format % {pass: pass, run: i+1}
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
