# Show help
def help
  puts "Usage: #{$0} [options]"
  puts "Options:"
  puts "\t-h|--help\t\tThis help"
  puts "\t-d|--debug\t\tDon't run in daemon mode"
  puts "\t-n|--dry-run\t\tPerform no actions"
  puts "\t-c|--config-file\tConfiguration file path.\n\t\t\t\t(defaults: config.rb, /etc/kunoichi/config.rb)"
  puts "\t-i|--import\t\tImport configuration from ninja and writes to stdout."
  puts "\t-g|--generate-config\tGenerate sample configuration file"
  puts "\t-p|--pid-file\t\tPid file path"
  exit
end

# Try to include yaml configuration
def include_conf(file)
  begin
    raise 'empty file' unless readconf = YAML.load_file(file)
  rescue => e
    puts "Cannot load configuration: #{e.message}"
    exit
  end
  @config = readconf.merge! @config
  @config[:loaded] = true
end

# Parse a ninja configuration file and return kunoichi yaml configuration
def import_conf(file)

  # Try to open the file
  begin
    ninja = File.read(file)
  rescue => e
    puts 'Cannot open ninja configuration file: ' + e.message
    exit
  end

  # Initialize parsed old configuration and new configuration hashes
  oldconf = {}
  newconf = {}

  # Transform ninja configuration, comments excluded, in a ruby hash
  ninja.lines.grep(/^[^#\n].* = /).each do |x|
    key=x.split('=')[0].strip!
    value=x.split('=')[1].strip!
    oldconf[key] = value
  end

  # For each of the values that kunoichi understands
  Kunoichi::DEFAULTS.keys.each do |x|
    # If it was not declared, return the default value
    if oldconf[x].nil? then
      newconf[x] = Kunoichi::DEFAULTS[x]
    else
      # If there was the setting, turn yes/no/(null) into booleans
      case oldconf[x]
        when 'yes'
          newconf[x] = true
        when 'no', '(null)'
          newconf[x] = false
        else
          # Since all values are strings, turn to integer those that require it
          if [ 'group', 'interval', 'proc_scan_offset' ].include? x
            newconf[x] = oldconf[x].to_i
          else
            # Save the old value
            newconf[x] = oldconf[x]
          end
      end
    end
  end

  # Return the newly filled hash in yaml format, preceded by some useful comments.
  return Kunoichi::CONFIGURATION_HEADER + newconf.to_yaml
end
  
# Generate a configuration file, starting from defaults
def generate_conf(file)
  # Take care not to overwrite the configuration by mistake
  if File.exist? file
    puts "File #{file} already existing."
    return
  end
  begin
    conf = File.open(file,'w+')
  rescue => e
    puts "Error creating file: #{e.message}"
    return
  end
  begin
    # Write some useful comments, and the defaults dump in yaml
    conf.write Kunoichi::CONFIGURATION_HEADER +
               Kunoichi::DEFAULTS.to_yaml
  rescue => e
    puts "Error writing to file: #{e.message}"
    return
  end
  puts "Sample configuration written to #{file}."
  conf.close
  exit
end
