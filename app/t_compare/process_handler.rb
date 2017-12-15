require 'multi_json'
require 'get_process_mem'
require 'memoizer'

class TCompare
  class ProcessHandler
    include Memoizer
    # Todo: Replace complex pipe with Open3.pipeline_start

    attr_reader :outline, :interpreter, :process_id

    def initialize(interpreter, outline)
      @interpreter = interpreter
      @outline = outline

      @in_writer, @out_reader, @process_id = fork_process

      puts "PID: #{@process_id}"

      warm_up

      debug "Controller spawned #{interpreter['name']} (debug: #{outline[:debug].inspect})"
    end

    def run_iterations(n)
      if n > 0
        debug "Controller of #{interpreter['name']}: #{n} ITERS"
        @in_writer.write "ITERS #{n.to_i}\n"
        state = :failed

        t_start = Time.now
        loop do
          state, break_loop = do_iteration
          break if break_loop
        end
        t_end = Time.now

        unless [:succeeded, :succeeded_measure_time].include?(state)
          debug "Killing process #{interpreter['name']} after failed iterations, error code #{state.inspect}"
          self.kill
        end

        if state == :succeeded_measure_time
          @last_run = [(t_end - t_start).to_f]
        end
      end
      @last_run
    end

    def quit
      debug "Controller of #{interpreter['name']}: QUIT"
      @in_writer.write "QUIT\n"
    end

    def kill
      debug "Controller of #{interpreter['name']}: DIE"
      ::Process.detach @process_id
      ::Process.kill "TERM", @process_id
    end

    def memory
      @memory_spy ||= GetProcessMem.new(ppid)
      @memory_spy.mb
    end

    def ppid
      `pgrep -P #{@process_id}`.strip
    end
    memoize :ppid

    private

    def fork_process
      in_reader, in_writer = IO.pipe
      out_reader, out_writer = IO.pipe
      in_writer.sync = true
      out_writer.sync = true

      debug "Controller of nobody yet: SPAWN"
      process_id = fork do
        STDOUT.reopen(out_writer)
        STDIN.reopen(in_reader)
        out_reader.close
        in_writer.close

        ENV['ABDEBUG'] = outline[:debug].inspect
        exec spawn_command
        exit! 0 # Skip exit handlers
      end

      out_writer.close
      in_reader.close

      [in_writer, out_reader, process_id]
    end

    def warm_up
      if outline[:warmup] > 0
        puts "* Running #{outline[:warmup]} warmup trials for #{interpreter['name']}"
        outline[:warmup].times do
          run_iterations(outline[:input_size])
        end
      end
    end

    def debug(string)
      STDERR.puts(string) if outline[:debug]
    end

    def spawn_command
      TCompare::Interpreter.ruby_as(interpreter, outline[:test_file])
    end

    def do_iteration
      # Read and block
      state = :failed
      break_loop = false
      output = @out_reader.gets
      debug "Controller of #{interpreter['name']} out: #{output.inspect}"

      if output =~ /^(VALUE|OK$|NOT OK$)/
        break_loop = true
        state = process_output_state(output)
      end

      # None of these? Loop again.
      [state, break_loop]
    end

    def process_output_state(output)
      if output =~ /^VALUES/ # These anchors match newlines, too
        values = MultiJson.load output[7..-1]
        raise "Must return an array value from iterations!" unless values.is_a?(Array)
        raise "Must return an array of numbers from iterations!" unless values[0].is_a?(Numeric)
        @last_run = values
        :succeeded
      elsif output =~ /^VALUE/ # These anchors match newlines, too
        value = output[6..-1].to_f
        raise "Must return a number from iterations!" unless value.is_a?(Numeric)
        @last_run = [value]
        :succeeded
      elsif output =~ /^OK$/
        :succeeded_measure_time
      elsif output =~ /^NOT OK$/
        :explicit_not_ok
        #elsif ignored_out > 10_000
        #  # 10k of output and no OK? Bail with failed state.
        #  :too_much_output_without_status
        # Should be re-enabled if we return to implementing I/O tests
      else
        :failed
      end
    end

    def memory_for_pid(pid)
      #`ps -o rss= -p #{pid}`.chomp
      `less /proc/#{pid}/status | grep RSS`
    end
  end
end