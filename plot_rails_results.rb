#!/usr/bin/env ruby
require 'byebug'
require 'rmagick'
require 'csv'
require 'json'

X_MIN, X_MAX = 0, 100

def plot_app_results
  apps = JSON.parse(File.read('applications.json'))
  apps.each do |app|
    app['views'].map(&name).each do |view_name|
      plot_view(app, view_name)
    end
    generate_outline_file(app)
  end
end

def plot_view(app, view_name)
  puts "Plotting #{app['name']} | #{view_name}"
  result_path = "results/applications/#{app['name']}"
  interpreter_results = app['interpreters'].collect do |interpreter|
    CSV.table("#{result_path}/#{interpreter["name"]}/#{view_name}.tsv", col_sep: "\t")
  end
  i = 0
  interpreter_min_max_seconds = app['interpreters'].map(&name).collect do |interpreter_name|
    minmax = interpreter_results[i].map { |row| row[:seconds] }.minmax
    i += 1
    [interpreter_name, {
      min: minmax.min,
      max: minmax.max,
      diff: minmax.max - minmax.min
    }]
  end.to_h

  bare_minimum, bare_maximum = interpreter_results.flat_map {|row| row[:ttime]}.minmax
  bare_minimum = (bare_minimum / 1.25).round
  bare_minimum = [bare_minimum, 1].max
  bare_maximum = roundup(bare_maximum * 1)
  ytics = [1]
  loop do
    ytics << roundup(ytics.last * 1.25)
    break if ytics.last > bare_maximum
  end
  gnuplot_commands =
    %Q(
      # Output to a jpeg file
      set terminal png size 900,300

      # Set the aspect ratio of the graph
      set size 1, 1

      # The graph title
      # set title "#{app['name']}: #{view_name}"

      # Where to place the legend/key
      set key outside right top

      # Draw gridlines oriented on the y axis
      set grid y

      # The file to write to
      set output "#{result_path}/#{view_name}.png"

      set datafile separator '\t'

      unset xtics
      set xrange [#{X_MIN - 5}:#{X_MAX + 5}]
      # set xlabel 'Chronologically ordered requests (s)'

      # Label the y-axis
      # set ylabel "Response time (ms)"
      set log y 10
      set yrange [#{bare_minimum}: #{bare_maximum}]
      set ytics nomirror norotate (#{ytics.join(',')})
      # set format y "%2.0l{/Symbol \327}10^{%L}"
      # set mytics 1000     ##{interpreter_min_max_seconds.values.map { |h| h[:diff] }.max / 10}
  )
  gnuplot_commands += 'plot ' + app['interpreters'].map(&name).flat_map do |interpreter_name|
      # Plot the data, start at the second row, x|y = columns 2 (seconds) and 5 (ttime)
      %Q("#{result_path}/#{interpreter_name}/#{view_name}.tsv" every ::2 using (#{normalize('$2', interpreter_min_max_seconds[interpreter_name])}):5 title '#{interpreter_name}' with points pointsize 1)
  end.join(',')

  IO.popen("gnuplot", "w") {|io| io.puts gnuplot_commands}
  Magick::Image.read("#{result_path}/#{view_name}.png").first.display
end

def generate_outline_file(app)
  outline_path = "results/applications/#{app['name']}/outline.csv"
  CSV.open(outline_path, 'w') do |csv|
    csv << ['concurrency', app['concurrency']]
    csv << ['requests',    app['requests']]
    csv << ['warmup',      app['warmup']]
  end
  puts "Outline file written to #{outline_path}"
end

def name
  proc { |node| node["name"] }
end

def normalize(value, range)
  "(((#{value} - #{range[:min]}) * #{X_MAX}) / #{range[:diff]}) + #{X_MIN}"
end

def roundup(num)
  x = Math.log10(num).floor
  (num/(10.0**x)).ceil * 10**x
end

plot_app_results