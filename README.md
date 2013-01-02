# Kunoichi

Kunoichi is a Ruby rewrite of Tom Rune Flo's [Ninja](http://forkbomb.org/ninja), a privilege escalation monitor.

It supports all ninja's features, and can be used as an (almost, see migration below) drop-in replacement.

## Usage

You can start Kunoichi with `-h|--help` to see the runtime options, or with no arguments to run it normally.

On startup Kunoichi will look for the configuration file (`config.yml`) in the current working directory and in /etc/kunoichi.

You can generate a sample configuration file with reasonable defaults by running:

    # kunoichi -g

You can also reuse your ninja configuration.

## Migrating from ninja

If you already had a properly configured ninja and would like to try Kunoichi with the same configuration, you can
import it by running:

    # kunoichi -i /etc/ninja/ninja.conf > config.yml

The whitelist format is the same.

## Configuration options

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

## Environment

When an external command is launched, it has these environment variables available:

* *EVIL_PID* - The pid of the offending process
* *EVIL_CMD* - The content of /proc/pid/cmdline, human readable
* *EVIL_NAME* - First entry in cmdline
* *EVIL_BIN* - /proc/pid/exe target of the process
* *EVIL_PPID* - The parent pid of the offending process
* *EVIL_PCMD* - The content of parent's /proc/pid/cmdline, human readable
* *EVIL_PNAME* - First entry in parent's cmdline
* *EVIL_PBIN* - /proc/pid/exe target of the parent process

## Whitelisting

Whitelist entries are full paths to setuid root binaries that can be executed by any user. 
Lines starting with a # will be ignored.

Example:

    # Let everyone use sudo
    /usr/bin/sudo
    # Also allow /bin/su
    /bin/su

## Author

Kunoichi was written by Alessandro Grassi <alessandro@aggro.it>.

## License

Kunoichi is released under the terms of GNU General Public License version 3

## Credits

The author would like to thank Tom Rune Flo for writing the original ninja, and for being an
overall kind person.

