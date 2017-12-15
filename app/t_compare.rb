require 'statsample'
require 'colorize'
require 'get_process_mem'
require 'byebug'

class TCompare

  attr_reader :outline, :evaluation

  FIRST_TRIAL_WITH_PTEST = 2 # No of examples needed for a Students t-test
  MINIMUM_TRIAL_COUNT = 5 # No of examples for Gnu-Plotting

  def initialize(options)
    @outline = Outline.new(options)
  end

  def run_full_evaluation(regexp)
    Outline.scripts.each do |test_file, defaults|
      if test_file =~ regexp
        defaults[:test_file] = test_file
        outline.reinitialize(defaults)
        puts Summary::Base.heading("Running T-Tests for #{test_file}").green
        @base_evaluation = nil
        evaluate_and_summarize_script
      end
    end
  end

  def summarize_scripts
    outline[:reload_old_results] = true
    compact_evaluations = load_compact_evaluations
    Summarizer.new(compact_evaluations).dump
  end

  private

  def load_compact_evaluations
    Outline.scripts.map do |test_file, defaults|
      defaults[:test_file] = test_file
      outline.reinitialize(defaults)
      @base_evaluation = nil
      [outline[:name], evaluate_script]
    end.to_h
  end

  def evaluate_and_summarize_script
    evaluation_statistics = evaluate_script
    Summary::Final.new(outline, evaluation_statistics).print
  end

  def evaluate_script
    ([Interpreter.base] + Interpreter.versus).map do |interpreter|
      restore_or_run_evaluation(interpreter)
    end
  end

  def restore_or_run_evaluation(interpreter)
    # Omg so ugly.
    if outline[:reload_old_results]
      begin
        restore_results(interpreter)
      rescue Exception
        puts "No or corrupted data, re-running the test"
        run_evaluation(interpreter)
      end
    else
      run_evaluation(interpreter)
    end
  end

  def restore_results(interpreter)
    evaluation = TCompare::Evaluation::Base.new(interpreter, @outline, @base_evaluation)
    evaluation.restore
    @base_evaluation ||= evaluation
    evaluation.to_bare_minimum
  end

  def run_evaluation(interpreter)
    evaluation = evaluate_script_on_interpreter(interpreter)
    @base_evaluation ||= evaluation
    evaluation.summarize
    evaluation.to_bare_minimum
  end

  def evaluate_script_on_interpreter(interpreter)
    run_forked do
      # Todo: Replace with Open3 pipeline
      @process = ProcessHandler.new(interpreter, @outline)

      evaluation = inner_evaluation(interpreter)

      # Clean up processes
      @process.kill
      evaluation
    end
  end

  def inner_evaluation(interpreter)
    @evaluation = TCompare::Evaluation::Base.new(interpreter, @outline, @base_evaluation)
    puts Summary::Base.heading("Evaluating: [#{evaluation.interpreter_name}]").light_blue
    run_sampling
    evaluation
  end

  def run_sampling
    @start_wall_clock_time = Time.now
    print "Start Time: #{@start_wall_clock_time.to_s}\n"
    trial = 0
    loop do
      trial += 1
      elapsed_seconds = Time.now - @start_wall_clock_time
      break if elapsed_seconds > outline[:measured_runtime]

      evaluation.sample_durations << elapsed_seconds

      print "\rTrial #{trial} \t (#{elapsed_seconds.round}s / #{outline[:measured_runtime]}s)"
      sample_one_trial

      unless evaluation.samples.size < FIRST_TRIAL_WITH_PTEST || is_base_evaluation?
        evaluation.run_and_add_p_test
      end
    end
    print "\n\n"
  end

  def sample_one_trial
    evaluation.samples += @process.run_iterations(outline[:input_size])
    evaluation.memory_footprints << @process.memory
    evaluation.iterations += 1
  end

  def run_forked
    reader, writer = IO.pipe

    pid = fork do
      reader.close
      writer.write(Marshal.dump(yield))
      exit!(0) # skips exit handlers.
    end

    writer.close
    result = reader.read
    Process.wait(pid)
    raise "child failed" if result.empty?
    Evaluation::Base  # Autoloading does not work in Marshall. Todo: Find a more general solution than tapping every used object
    Marshal.load(result)
  end

  def is_base_evaluation?
    @base_evaluation.nil?
  end
end