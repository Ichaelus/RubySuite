class TCompare
  class Worker

    class << self

      def n_iterations_measured(&block) #was: iteration
        new(:n_iterations_measured, &block)
      end

      def parametrized_iteration_measured(&block) #was: n_iterations_with_return_value / per_n_iteration
        new(:parametrized_iteration_measured, &block)
      end
      def n_incremental_iterations_measured(&block)
        new(:n_incremental_iterations_measured, &block)
      end

      def n_iterations_with_value(&block) #was iteration_with_return_value / :per_iteration
        new(:n_iterations_with_value, &block)
      end

      def n_parametrized_iterations_with_value(&block)
        new(:n_parametrized_iterations_with_value, &block)
      end
    end

    def initialize(iteration_type, &block)
      @iteration_type = iteration_type
      @iteration_block = block
    end

    def run_n(n)
      debug "WORKER #{Process.pid}: running #{n} times [#{@iteration_type.inspect}]"
      case @iteration_type
        when :n_iterations_measured
          # Run n times the same (!) program, with total time measured.
          # You might want to set iterations to 1 and increase trial count for a better insight.
          n.times do |i|
            @iteration_block.call
          end
          STDOUT.write "OK\n"
        when :parametrized_iteration_measured
          # Run one time with with the input value n. Total time is measured.
          @iteration_block.call(n)
          STDOUT.write "OK\n"
        when :n_incremental_iterations_measured
          # Run n times with increasing input value from [0,..,n-1]. Total time is measured.
          n.times do |i|
            @iteration_block.call(i)
          end
          STDOUT.write "OK\n"
        when :n_iterations_with_value
          # Run n times the same (!) program. Returns an array of resulting values
          STDERR.puts 'CAUTION: T-Test ist paired and not independent. Decrease iterations to 1.' if n > 1
          values = (0..(n-1)).map do
            @iteration_block.call.to_f
          end
          STDOUT.write "VALUES #{values.inspect}\n"
        when :n_parametrized_iterations_with_value
          # Run n times with increasing input value. Returns an array of resulting values
          values = (0..(n-1)).map do |i|
            @iteration_block.call(i).to_f
          end
          # Return array of numbers
          debug "WORKER #{Process.pid}: Sent to controller: VALUES #{values.to_a.inspect}"
          STDOUT.write "VALUES #{value.to_a.inspect}\n"
        else
          raise "Unknown @iteration_type value #{@iteration_type.inspect} inside the process worker!"
      end
    end

    def read_once
      debug "WORKER #{Process.pid}: read loop"
      @input ||= ""
      @input += (STDIN.gets || "")
      debug "WORKER #{Process.pid}: Input #{@input.inspect}"
      if @input["\n"]
        command, @input = @input.split("\n", 2)
        debug "WORKER #{Process.pid}: command: #{command.inspect}"
        if command == "QUIT"
          exit 0
        elsif command["ITERS"]
          iterations = command[5..-1].to_i
          run_n(iterations)
          STDOUT.flush  # Why does this synchronous file descriptor not flush when given a string with a newline? Ugh!
          debug "WORKER #{Process.pid}: finished command ITERS: OK"
        else
          STDERR.puts "Unrecognized protocol command: #{command.inspect}!"
          exit -1
        end
      else
        exit -1
      end
    end

    def start
      loop do
        read_once
      end
    end

    private

    def debug(string)
      STDERR.puts(string) if ENV['ABDEBUG'] == "true"
    end
  end
end