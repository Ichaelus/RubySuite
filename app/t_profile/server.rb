require 'open3'
require 'get_process_mem'
require 'byebug'

class TProfile
  # Todo: Merge with HarnessProcess -> Good base class
  class Server
    def initialize(application_variant)
      @variant = application_variant
      puts "TCP traffic on port 3000 (should be nil):"
      puts current_rails_servers
    end

    def measure_memory_usage
      GetProcessMem.new(process_pid).mb
    end

    def kill
      puts "Shutting down the server"
      # Soft, e.g. "passenger stop"
      stop_variant_server
      # Hard: Kill subprocess ID
      ::Process.detach process_pid
      ::Process.kill "KILL", process_pid
      # Hardest: Stop everything that interacts with port 3000
      5.times do
        `fuser -kn tcp 3000`
        break unless running?
        sleep(1)
      end
      #group_id = ::Process.getpgid(@process_ppid)
      #::Process.kill "TERM", group_id * -1
      #::Process.kill "KILL", group_id * -1
    end

    def run
      begin
        @process_ppid = start_variant_server
        ensure_ping_receiving do
          print_current_rails_server
          yield
        end
        peak_memory = measure_memory_usage
      rescue SystemExit, Interrupt, Exception => e
        puts "Unexpected Exception. Killing rails.."
        puts e
        kill
        raise e
      end
      kill
      peak_memory
    end

    def current_rails_servers
      `fuser -n tcp 3000`
    end

    private

    def start_variant_server
      command = TCompare::Interpreter.ruby_as(@variant, "#{@variant['start_command']}")
      r, w = IO.pipe
      r2, w2 = IO.pipe
      Open3.pipeline_start(command, chdir: @variant['path'], in: r, out: w2).first.pid
    end

    def stop_variant_server
      if @variant['stop_command']
        command = TCompare::Interpreter.ruby_as(@variant, "#{@variant['stop_command']}")
        Open3.pipeline(command, chdir: @variant['path'])
      end
    end

    def ensure_ping_receiving
      30.times do
        if running?
          puts 'Server up and running'
          yield
          break
        else
          sleep(1)
        end
      end
    end

    def running?
      `lsof -wni tcp:3000`.length > 0 # Inaccurate, includes listeners
    end

    def print_current_rails_server
      puts "Ruby interpreter: #{process_command(process_pid)}"
      puts "Application directory: #{app_dir(process_pid)}"
    end

    def process_pid
      `pgrep -P #{@process_ppid}`.to_i
    end

    def app_dir(pid)
      `pwdx #{pid}`
    end

    def process_command(pid)
      `readlink -f /proc/#{pid}/exe`
    end

  end
end