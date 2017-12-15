require 'json'
require 'open3'
require 'csv'
require 'fileutils'
require 'byebug'

class StartUp

  STARTUP_TRIALS = 1000

  attr_reader :outline
  def initialize
    @outline = TCompare::Outline.new(warmup_outline)
  end

  def run
    interpreters = [TCompare::Interpreter.base] + TCompare::Interpreter.versus
    interpreters.each do |interpreter|
      name = interpreter['name']
      trial_times, trial_memory_usages = evaluate_startup_times(interpreter).transpose
      write_to_csv(([name] + trial_times).map{|e|[e]}, interpreter_csv("#{name}_times"))
      write_to_csv(([name] + trial_memory_usages).map{|e|[e]}, interpreter_csv("#{name}_memory"))
    end
    merge_csvs(interpreters)
  end

  private

  def evaluate_startup_times(interpreter)
    puts "Measuring: #{interpreter['name']}"
    (1..STARTUP_TRIALS).map do |i|
      run_forked do
        start = Time.now
        memory_usage = spawn_execute_kill(interpreter).to_f
        raise "Unexpected answer from script: #{memory_usage}" unless memory_usage > 0
        time_consumption = Time.now - start
        print "\r (#{i} / #{STARTUP_TRIALS}\t: #{round_to(time_consumption, 4)}s | #{round_to(memory_usage, 4)}mb"
        [time_consumption, memory_usage]
      end
    end.tap { print("\n\n") }
  end

  def warmup_outline
    {
      warmup: 1,
      input_size: 1,
      test_file: 'startup.rb'
    }
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
    Marshal.load(result)
  end

  def spawn_execute_kill(interpreter)
    command = TCompare::Interpreter.inline_ruby_as(
      interpreter,
      "'require \"rubygems\"; require \"get_process_mem\"; puts GetProcessMem.new.mb'"
    )
    last_stdout, wait_threads = Open3.pipeline_r(command)
    last_stdout.read
  end

  def interpreter_csv(name)
    outline.result_file("#{name}.csv")
  end

  def merge_csvs(interpreters)
    time_csvs, memory_csvs = interpreters.map do |interpreter|
      csvs_for_interpreter(interpreter)
    end.transpose
    save_summary_csv(time_csvs, 'times')
    save_summary_csv(memory_csvs, 'memory')
    generate_brief_summary(time_csvs, memory_csvs)
  end

  def save_summary_csv(csvs, type)
    write_to_csv(csvs.transpose.map(&:flatten), outline.result_file("#{type}.csv"))
  end

  def csvs_for_interpreter(interpreter)
    [csv_for_interpreter(interpreter, 'times'),
     csv_for_interpreter(interpreter, 'memory')]
  end

  def csv_for_interpreter(interpreter, type)
    filename = interpreter_csv(("#{interpreter['name']}_#{type}"))
    csv = CSV.read(filename)
    FileUtils.rm(filename)
    csv
  end

  def generate_brief_summary(time_csvs, memory_csvs)
    rows = [['TRIALS', STARTUP_TRIALS]]
    rows += type_based_summary_rows(time_csvs, 'times')
    rows += type_based_summary_rows(memory_csvs, 'memory')
    write_to_csv(rows, outline.result_file('summary.csv'))
  end

  def type_based_summary_rows(csvs, type)
    interpreter_hash_with_values = csvs.collect {|c|
      [c.first.first, c.drop(1).flatten.map {|v| v.to_f}]
    }.to_h
    interpreter_hash_with_values.inject([]) do |rows, (interpreter, values)|
      rows << ["#{interpreter}-min-#{type}", round_to(values.min, 2)]
      rows << ["#{interpreter}-max-#{type}", round_to(values.max, 2)]
      rows << ["#{interpreter}-median-#{type}", round_to(TCompare::Evaluation::Base.median(values), 2)]
      rows << ["#{interpreter}-mean-#{type}", round_to(TCompare::Evaluation::Base.mean(values), 2)]
    end
  end

  def round_to(value, n)
    sprintf("%1.#{n}f", value)
  end

  def write_to_csv(rows, filepath)
    CSV.open(filepath, 'w') do |csv|
      rows.each do |row|
        csv << row
      end
    end
  end
end
