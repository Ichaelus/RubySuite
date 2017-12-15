require 'json'
require 'open3'
require 'statsample'
require 'colorize'
require 'csv'
require 'byebug'

class TProfile

  def initialize(options)
    @options = options
  end

  def run_full_evaluation(regexp)
    applications.each do |app|#{(app)}
      @current_application = app
      if app['name'] =~ regexp
        puts TCompare::Summary::Base.heading("Profiling #{app['name']}").green
        CSV.open("#{application_dir(app)}/peak_memory.csv", 'w') do |memory_csv|
          app['interpreters'].each do |interpreter|
            @current_interpreter = interpreter
            peak_memory_usage = profile_interpreter
            memory_csv << [interpreter['name'], peak_memory_usage]
          end
        end
      end
    end
  end

  def summarize_median_results
    interpreter_views = applications.first['interpreters'].map do |interpreter|
      applications.flat_map do |app|
        view_names(app).map do |view|
          median(CSV.read("#{output_dir(app, interpreter)}/#{view}.tsv", col_sep: "\t", headers: true)['ttime'].map(&:to_i))
        end
      end
    end
    view_medians = interpreter_views.transpose.map {|view_median| relative_to_first(view_median)}
    view_names = applications.flat_map {|app| view_names(app)}
    rows = [[''] + interpreter_names(applications.first)]
    rows += ([view_names] + view_medians.transpose).transpose
    write_to_csv(rows, "results/applications/summary.csv")
  end

  private

  def view_names(app)
    app['views'].map {|v| v['name']}
  end

  def interpreter_names(app)
    app['interpreters'].map {|i| i['name']}
  end

  def applications
    JSON.parse File.read('applications.json')
  end

  def profile_interpreter
    puts TCompare::Summary::Base.heading("Interpreter: #{@current_interpreter['name']}").light_yellow
    TProfile::Server.new(@current_interpreter).run do
      evaluate_views
    end
  end

  def evaluate_views
    @current_application['views'].each do |view|
      puts TCompare::Summary::Base.heading("Evaluating View: #{view['name']}").light_blue
      puts Time.now.to_s
      run_warmup(view)
      evaluate_view(view)
    end
  end

  def run_warmup(view)
    puts TCompare::Summary::Base.heading("#{@current_application['warmup']} warmup requests running..")
    warmup_mean = @current_application['warmup'].times.map do
      start = Time.now
      Open3.pipeline(view['curl_command'] + ' -s > /dev/null')
      Time.now - start
    end.mean
    puts "Warmup request mean time: #{warmup_mean}"
  end

  def evaluate_view(view)
    puts TCompare::Summary::Base.heading("#{@current_application['requests']} requests are evaluated and plotted..")
    Open3.pipeline(ab_command_for_view(view), chdir: output_dir(@current_application, @current_interpreter))
    Plot.view_response_times(view['name'], output_dir(@current_application, @current_interpreter))
  end

  def ab_command_for_view(view)
    "
    ab  -n #{@current_application['requests']}
        -c #{@current_application['concurrency']}
        -e \"#{view['name']}.csv\"
        -g \"#{view['name']}.tsv\"
        -s 400
        -v 0
        '#{view['url']}'
        > \"ab-results #{view['name']}.txt\"
    ".gsub("\n", '')
  end

  def output_dir(application, interpreter)
    # Where to store results
    dir!("#{application_dir(application)}/#{interpreter['name']}")
  end

  def application_dir(application)
    dir! "results/applications/#{application['name']}"
  end

  def dir!(path)
    Dir.mkdir(path) unless File.exists?(path)
    path
  end

  def median(samples)
    sorted = samples.sort
    if samples.size % 2 == 1
      # For odd-length, take middle element
      sorted[ samples.size / 2 ]
    else
      # For even length, mean of two middle elements
      (sorted[ samples.size / 2 ] + sorted[ samples.size / 2 - 1 ]) / 2.0
    end
  end

  def relative_to_first(floats)
    base = floats.first
    floats.map { |value|
      round_to(base / value, 2)
    }
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