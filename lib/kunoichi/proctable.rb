# Accessory class to access informations about a process
class ProcEntry

  attr_accessor :pid, :cmdline, :name, :binary, :uid, :gid, :parent

  # Fetch all the values when the object is created
  def initialize(pid)
    raise 'invalid pid: not a number' unless pid.is_a? Fixnum
    pids = pid.to_s
    raise 'invalid pid: not running' unless File.directory? "/proc/#{pids}"
    begin
      @pid = pid
      @cmdline = File.read("/proc/#{pids}/cmdline").gsub("\0", ' ')
      @name = @cmdline.split[0]
      @uid = File.stat("/proc/#{pids}/").uid
      @gid = File.stat("/proc/#{pids}/").gid
      @binary = File.readlink("/proc/#{pids}/exe")
      @parent = File.readlines("/proc/#{pids}/status").grep(/^PPid:/).first.split[1].to_i
    rescue => e
      raise "can't get process info: #{e.message}"
    end
  end
end
