class CLI

  attr_reader :options

  def initialize(options)
    @options = options
    if options[:test_scripts] || options[:test_scripts_regex]
      test_scripts(options[:test_scripts_regex])
    elsif options[:test_applications]
      test_applications
    elsif options[:test_applications_regex]
      test_applications(options[:test_applications_regex])
    elsif options[:measure_startup_time]
      measure_startup_time
    elsif options[:base]
      print_base_interpreter
    elsif options[:versus]
      print_compared_interpreters
    elsif options[:bundle]
      TCompare::Interpreter.bundle
    elsif options[:scripts]
      print_scripts
    elsif options[:summarize_scripts]
      summarize_scripts
    elsif options[:summarize_apps]
      summarize_apps
    elsif options[:show_result]
      show_result(options[:show_result])
    else
      puts "Invalid syntax. See #{$0} --help"
      exit 2
    end
  end

  private

  def test_scripts(searchstring = nil)
    puts TCompare::Summary::Base.heading("Running T-Tests for all scripts#{" that match '#{searchstring}'" unless searchstring.nil?}")
    TCompare.new(options).run_full_evaluation(Regexp.new(searchstring || ''))
  end

  def test_applications(searchstring = '')
    puts TCompare::Summary::Base.heading('Profiling real world applications')
    TProfile.new(options).run_full_evaluation(Regexp.new(searchstring))
  end

  def measure_startup_time
    puts TCompare::Summary::Base.heading('Measuring interpreter startup time')
    StartUp.new.run
  end

  def print_base_interpreter
    puts "Base interpreter: #{TCompare::Interpreter.base['name']}\n"
    puts "\nEvery other interpreter is compared with it."
  end

  def print_compared_interpreters
    puts "List of tested interpreters:\n\n"
    puts TCompare::Interpreter.versus.map{|int| "* #{int['name']}\n"}
    puts "\nEach of them is tested against the base interpreter."
  end

  def print_scripts
    puts "List of scripts:\n\n"
    puts TCompare::Outline.scripts.keys.map{|path| "* #{path}\n"}
    puts "\nYou can test them running #{$0} --test-scripts."
  end

  def summarize_scripts
    puts TCompare::Summary::Base.heading('Generating overall script summary')
    TCompare.new(options).summarize_scripts
  end

  def summarize_apps
    puts TCompare::Summary::Base.heading('Generating overall app summary')
    TProfile.new(options).summarize_median_results
  end

  def show_result(example_regex = '')
    require 'rmagick'
    outline = TCompare::Outline.new(options)
    puts TCompare::Summary::Base.heading("Showing past results for examples matching '#{example_regex}'")
    TCompare::Outline.scripts.keys.each do |test_file|
      if test_file =~ Regexp.new(example_regex)
        outline[:test_file] = test_file
        Magick::Image.read(outline.result_file('summary_boxplot.png')).first.display
      end
    end
  end

end