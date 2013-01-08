Kunoichi(1) -- A process privilege escalation monitor
=====================================================

## SYNOPSIS

`kunoichi` [<OPTION>]...

## DESCRIPTION

Kunoichi is a Ruby rewrite of *ninja(1)*, a privilege escalation monitor.

It is an almost drop-in replacement for Ninja, as in it supports all
the features supported by Ninja and is able to generate its configuration
starting from a Ninja configuration file.

## RUNNING

On startup Kunoichi will look for the configuration file (`config.yml`) in the current working directory and in /etc/kunoichi.

A different configuration file can be supplied with `-c` (see below).

You can start Kunoichi with `-h|--help` to see the runtime options, or with no arguments to run it normally.

## OPTIONS

Kunoichi supports some runtime options to change its behavior, overriding the configuration.

### Configuration overrides:

  * `-n`,`--dry-run`:
    Perform no actions. This sets *no_kill* and *no_kill_ppid* to true.
    
  * `-d`,`--debug`:
    Run in debug mode. This provides extended logging and sets *daemon*, *syslog* and *logfile* to false.

  * `-p`,`--pid-file` <file>:
    Write the pid to an alternate pid file than the one written in the configuration.

### Miscellaneous options:

  * `-h`,`--help`:
    Show a basic usage help.

  * `-c`,`--config-file` <file>:
    Load a different configuration file than the defaults (see *RUNNING* above).

  * `-i`,`--import` <file>:
    Load a configuration file for *ninja(1)* and print the Kunoichi equivalent configuration on STDOUT.

  * `-g`,`--generate-config` <file>:
    Generates a Kunoichi configuration file. If file is not specified, it writes to *config.yml*.

## FILES

Kunoichi works with two files, *config.yml* and the *whitelist*.

The configuration file is in YAML and can be generated from defaults or from an old ninja configuration (see above).

The whitelist is a list of executables that can be ran by anyone without issuing alerts.

A common example would be:

    # Enable sudo
    /usr/bin/sudo
    # Enable su
    /bin/su


## CONFIGURATION OPTIONS

These are the configuration options understood by Kunoichi:

* **group** - Sets the GID (Group ID) of the group of users that are allowed to run any root setuid/setgid
               binary. Programs executed by users in this group do not need to be whitelisted. _(default: 0)_
* **daemon** - If set to true, Kunoichi will run in the background as daemon. _(default: true)_
* **syslog** - If set to true, Kunoichi will log to syslog using facility _daemon_. _(default: true)_
* **interval** - The process scanning interval, in seconds. Can be float. This is the amount of time Kunoichi will sleep,
                  before going through all the active processes on the system. Lower intervals are safer, meaning
                  that the unauthorized processes will be detected faster. Unless your system is very slow, you should set
                  this to a value between zero and one. _(default: 1)_
* **logfile** - Path to log file. If specified, all messages are logged to this file. Can be used as an alternative to syslog.
                _(default: /var/log/kunoichi.log)_
* **pidfile** - Path to the pid file.  _(default: /var/run/kunoichi.pid)_
* **whitelist** - Path to the whitelist file. _(default: /etc/kunoichi/whitelist.txt)_
* **external_command** - Path to the external command. If you specify an external command, 
                          this command will be run every time an unauthorized process is detected.
                          This could be a script that alerts the admin of the system via e-mail, 
                          disables the login account of the offending user, among other things.
                          The command will have some information on the process available in the environment (see below).
                          _(default: /bin/true)_
* **no_kill** - If this option is enabled, unauthorized processes will not be killed when detected. This can be very
                 useful when testing the system, or when creating whitelists. _(default: true)_
* **no_kill_ppid** - Same as the *no_kill* option, except this one affects the ppid, parent of the unauthorized
                      process. _(default: true)_
* **ignore_root_procs** - When this option is enabled, all processes spawned by root, meaning processes with a parent
                           process owned by root, will be ignored. This is generally a good idea, and will save us some
                           cpu cycles. _(default: true)_
* **log_whitelist** - If enabled, Kunoichi will log every time it detects a whitelisted process running. _(default: true)_
* **require_init_wlist** - This option is very important for the security of your system. When this option is set to *true*,
                            all processes running as root, and controlled by init(1) will have to be whitelisted. If this
                            option is not enabled, attackers can circumvent Kunoichi by forking a new process after gaining
                            root, and create a new session (e.g. using setsid()). This will cause Kunoichi to believe that
                            root spawned this proces, as init(1) will now be the parent, and init(1) is owned by root.
                            Therefore, to gain a higher level of security, you should enable this option and explicitly
                            whitelist every process that will run in its own session, meaning that it will be controlled
                            by init(1). _(default: false)_
* **proc_scan_offset** - This option specifies the offset of which pids to scan. If set to 0, all processes on the system 
                          will be scanned. This might not be necessary, as processes with a pid lower than 300 is generally
                          kernel processes, and we really don't want to keep an eye on those. So, if you want to save a few
                          cpu cycles, set this to 300 or so. _(default: 0)_

Many of the descriptions here are based on ninja documentation, as their behavior is very similar.

## ENVIRONMENT

When an external command is launched, it has these environment variables available:

* *EVIL_PID* - The pid of the offending process
* *EVIL_CMD* - The content of /proc/pid/cmdline, human readable
* *EVIL_NAME* - First entry in cmdline
* *EVIL_BIN* - /proc/pid/exe target of the process
* *EVIL_PPID* - The parent pid of the offending process
* *EVIL_PCMD* - The content of parent's /proc/pid/cmdline, human readable
* *EVIL_PNAME* - First entry in parent's cmdline
* *EVIL_PBIN* - /proc/pid/exe target of the parent process

## COPYRIGHT

Kunoichi is Copyright (C) 2013 Alessandro Grassi <alessandro@aggro.it>.

## LICENSE

Kunoichi is released under the terms of GNU General Public License version 3

