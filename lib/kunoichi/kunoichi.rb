module Kunoichi
  # The main class, where all the dirty work happens
  class Daemon

    # Basic validator for configuration
    def validate_conf(config)

      # Base check, might be redundant
      raise 'invalid configuration passed: not an hash' unless config.is_a? Hash
      
      # Check for group validity
      raise 'invalid group: not a number' unless config['group'].is_a? Fixnum
      # Make sure the group exists on /etc/group
      begin
        Etc::getgrgid config['group']
      rescue => e
        raise "invalid group: #{e.message}"
      end

      # Check for daemon validity
      raise 'invalid daemon setting: please set to true or false' unless config['daemon'].is_bool?
      
      # Check interval
      raise 'invalid interval: please set to a number' unless config['interval'].is_a? Fixnum or config['interval'].is_a? Float
      # Useful warning in case no interval was declared
      puts 'WARNING: an interval of 0 can severely impact your machine performance. Use with caution.' if config['interval'] == 0

      # Check syslog
      raise 'invalid value for syslog: please set to true or false' unless config['syslog'].is_bool?

      # Check logfile
      raise 'set either syslog or logfile if daemon mode is enabled' unless config['syslog'] or config['logfile'].is_a? String or !config['daemon']
      raise 'invalid logfile setting: not writable' unless !config['logfile'] or File.writable? config['logfile'] or File.writable? File.dirname(config['logfile'])
      
      # Check whitelist
      raise 'invalid whitelist: set to a file path, or false to disable' unless config['whitelist'] == false or config['whitelist'].is_a? String
      raise "invalid whitelist: cannot open #{config['whitelist']}" unless config['whitelist'] == false or File.readable?(config['whitelist']) 

      # Check external_command
      raise 'invalid external_command: set to a file path, or false to disable' unless config['external_command'].is_a? String or config['external_command'] == false
      raise 'invalid external_command: not executable' unless !config['external_command'] or File.executable?(config['external_command'].split[0])

      # Check no_kill
      raise 'invalid no_kill: set to true or false' unless config['no_kill'].is_bool?

      # Check no_kill_ppid
      raise 'invalid no_kill_ppid: set to true or false' unless config['no_kill_ppid'].is_bool?

      # Check ignore_root_procs
      raise 'invalid ignore_root_procs: set to true or false' unless config['ignore_root_procs'].is_bool?

      # Check log_whitelist
      raise 'invalid log_whitelist: set to true or false' unless config['log_whitelist'].is_bool?

      # Check require_init_wlist
      raise 'invalid require_init_wlist: set to true or false' unless config['require_init_wlist'].is_bool?

      # Check proc_scan_offset
      raise 'invalid proc_scan_offset: set to a number' unless config['proc_scan_offset'].is_a? Fixnum
      raise "invalid proc_scan_offset: set lower than #{@max_pids}" unless config['proc_scan_offset'] < @max_pids

      # Check pidfile
      raise 'invalid pidfile setting: set to a string' unless config['pidfile'].is_a? String
      raise 'invalid pidfile setting: empty' if config['pidfile'].empty?
      raise 'invalid pidfile setting: not writable' unless File.writable? config['pidfile'] or File.writable? File.dirname(config['pidfile'])

      # Return the configuration if no errors encountered
      config
    end

    # Exit cleanly by logging our departure and deleting the pid file if we received a signal
    def clean_exit(sig)
      @log.info "Got SIG#{sig}, exiting."
      File.unlink(@config['pidfile']) if @config['daemon'] and @config['pidfile']
      exit
    end

    # Fetch the current running processes and put them into a ruby set
    # TODO: make this multi platform
    def get_process_list
      # Initialize the set
      entries = Set.new
      # Look up all pids
      Dir.glob('/proc/[0-9]*') { |x|
        # Turn pids to numbers
        pid = File.basename(x).to_i
        # Formal check for unexpected files on /proc starting with a digit
        next unless pid.to_s =~ /^[0-9]+$/
        # Skip processes above the configured offset
        if pid > @config['proc_scan_offset']
          entries.add pid
        end
      }

      return entries
    end

    # Load the whitelist
    def load_whitelist(file)
      # Open the file and read all words from lines that don't start with a #
      begin
        @whitelist = File.read(file).lines.grep(/^[^#]/).join.split
      rescue => e
        puts "Cannot load whitelist: #{e.message}"
        exit
      end
      # Warn the user of the whitelist was loaded but found empty
      if @whitelist.empty? 
        puts 'WARNING: Empty whitelist loaded.'
      end
    end

    # Run the external command
    def run_command(process,parent)

      # Log our action
      @log.info "Running external command: #{@config['external_command']}."

      # Prepare the environment with some useful informations
      ENV['EVIL_PID'] = process.pid.to_s
      ENV['EVIL_CMD'] = process.cmdline
      ENV['EVIL_NAME'] = process.name
      ENV['EVIL_BIN'] = process.binary

      ENV['EVIL_PPID'] = parent.pid.to_s
      ENV['EVIL_PCMD'] = parent.cmdline
      ENV['EVIL_PNAME'] = parent.name
      ENV['EVIL_PBIN'] = parent.binary

      # Launch the command
      system(@config['external_command'])
    end

    # Daemon startup procedure
    def initialize(config)
      # Check max pids first
      if RUBY_PLATFORM.downcase =~ /linux/
        begin
          @max_pids = File.read('/proc/sys/kernel/pid_max').to_i
        rescue
          raise 'Cannot read /proc/sys/kernel/pid_max (is /proc mounted?)'
        end
      else
        # Default on newer FreeBSD. Solaris should have a cap of 30000.
        # Makes only sense once get_process_list becomes multi-platform, but nice to have.
        @max_pids = 99999
      end

      # Validate configuration and store if valid
      @config = validate_conf config

      # Save the full path to the pid file in @config
      @config['pidfile'] = File.expand_path(@config['pidfile'])

      # Get initial process list at startup
      @initial_procs = get_process_list
      raise 'No processes found (is /proc mounted?)' if @initial_procs.empty?

      # Load the whitelist
      load_whitelist @config['whitelist'] if @config['whitelist']

      # Initialize @log as configured
      if @config['syslog']
        @log = Logger::Syslog.new('kunoichi', Syslog::LOG_DAEMON)
      else
        if @config['daemon'] 
          @log = Logger.new(@config['logfile'])
        else
          @log = Logger.new(STDOUT)
        end
      end

      # Enable debug info if running in debug mode, keep it quiet otherwise
      if @config['debug']
        @log.level = Logger::DEBUG
      else
        @log.level = Logger::INFO
      end

      @log.info 'Kunoichi starting up'

      # Daemonize if we're configured for it
      if @config['daemon']
        Process.daemon
        # Only write the pid file if we're running as daemon
        if @config['pidfile']
          begin
            File.open(@config['pidfile'], 'w+') { |x| x.write Process.pid.to_s }
          rescue => e
            @log.error e.message
          end
        end
      end

      # Catch SIGINT (^C) and SIGTERM (default kill)
      [ 'INT', 'TERM' ].each do |signal|
        Signal.trap signal do clean_exit signal end
      end

      # Finally, enter the main loop
      loop do 
        main_loop
        sleep @config['interval']
      end
    end

    # Main loop
    def main_loop
      @log.debug 'Checking processes:'
      # Get running processes
      procs = get_process_list
      # Extract the new processes since last loop cycle
      new_procs = procs - @initial_procs

      # Skip the run if there are new processes
      (@log.debug "\tNo new processes found."; return) if new_procs.empty?

      @log.debug "\tNew processes:"

      # For each new process:
      new_procs.each do |pid|
        # Extract information
        begin
          process = ProcEntry.new(pid)
        rescue
          # Skip if the process died before we could extract the info
          @log.debug "\t\t#{pid} - Disappeared before analysis"
          next
        end
        @log.debug "\t\t#{pid} - #{process.cmdline}"
         
        # If the process runs as root
        if process.uid == 0 

          # Attempt to identify the parent
          begin
            parent = ProcEntry.new(process.parent)
          rescue => e
            @log.warn "\t\tParent process of #{process.name} disappeared (#{e.message})."
            next
          end

          # Skip if the parent has the whitelisted gid
          next if parent.gid == @config['group']

          # If the parent is root
          if parent.uid == 0 
            # ..and we've chosen to ignore root spawned processes
            if @config['ignore_root_procs'] or parent.gid == @config['group']
              # if the parent is init
              if parent.pid == 1
                # spare the process unless configured otherwise
                unless @config['require_init_wlist']
                  next
                end
              # if the parent is not init everything is normal, just skip this one
              else
                next
              end
            end
          else
            # Also skip if the parent is not root, but is in the magic gid
            next if parent.gid == @config['group']
          end

          # Log our finding
          @log.info "\t\tFound offending process: #{pid} - #{process.cmdline}"

          # Skip if the executable is whitelisted
          if @config['whitelist'] and @whitelist.include? process.binary
            @log.info "\t\t\tAllowed(#{process.binary})." if @config['log_whitelist']
            next
          end
          
          # If we got this far it means the process deserves our attention

          # Terminate the process unless configured otherwise
          unless @config['no_kill'] 
            @log.info "\t\t\tTerminating."
            Process.kill(:KILL,pid)
          else
            @log.info "\t\t\tNot killing."
          end

          # Also kill the parent unless configured otherwise (or the parent is init)
          unless process.parent == 1 or @config['no_kill_ppid'] 
            @log.info "\t\t\tKilling parent too."
            Process.kill(:KILL,process.parent) 
          end

          # Run the external command in a subprocess
          fork { run_command(process,parent) } if @config['external_command'] 
        end
      end

      # Save the current process list for the next run
      @initial_procs = procs
    end
  end
end
