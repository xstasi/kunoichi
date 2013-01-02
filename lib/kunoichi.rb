require 'set'
require 'etc'
require 'yaml'
require 'logger'
require 'syslog-logger'
require 'getoptlong'

module Kunoichi
  DEFAULTS = {
    'group'              => 0,
    'daemon'             => true,
    'syslog'             => true,
    'interval'           => 1,
    'logfile'            => '/var/log/kunoichi.log',
    'pidfile'            => '/var/run/kunoichi.pid',
    'whitelist'          => '/etc/kunoichi/whitelist.txt',
    'external_command'   => '/bin/true',
    'no_kill'            => true,
    'no_kill_ppid'       => true,
    'ignore_root_procs'  => true,
    'log_whitelist'      => true,
    'require_init_wlist' => false,
    'proc_scan_offset'   => 0,
  }

  CONFIGURATION_HEADER = '## Kunoichi configuration file.
# Same options as ninja.
# Check the documentation to know what each option means.
# Documentation can be found on the project home page on github, 
#  or in README.md bundled with Kunoichi.
'

end

require 'extensions/object'
require 'kunoichi/proctable'
require 'kunoichi/kunoichi'
require 'kunoichi/cli'
