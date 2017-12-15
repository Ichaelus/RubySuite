class Plot
  class << self

    def box_plots_with_samples(outline, compact_evaluations)
      gnu_plot(box_plot_commands(outline, compact_evaluations))
      gnu_plot(runtime_commands(outline, compact_evaluations))
      gnu_plot(memory_commands(outline, compact_evaluations))
    end


    def view_response_times(view_name, path)
      gnu_plot(apache_bench_commands(view_name, path))
    end

    private

    ##
    # Plotting a boxplot of each interpreter on the x - axis along with their samples over time
    # The y - axis represents the sample score
    ##

    def box_plot_commands(outline, compact_evaluations)
      y_min = compact_evaluations.map { |e| e[:min_sample] }.min.round(2)
      y_max = compact_evaluations.map { |e| e[:max_sample] }.max.round(2)
      # If warmup is not included, it may influence the proportionality of the results
      x_tics, plot_commands = plot_evaluations(outline, compact_evaluations)

      default_plot_options(outline.test_file_name) +
      %Q(
        # The file to write to
        set output "#{outline.result_file('summary_boxplot.png')}"

        #set autoscale

        set border 2 front lt black linewidth 1.000 dashtype solid

        set boxwidth 0.5 absolute

        set style fill solid 0.50 border lt -1

        unset key

        set pointsize 0.5

        #set xtics border in scale 0,0 nomirror norotate  autojustify

        set xtics norangelimit nomirror (#{x_tics})
        set xrange [0.5:#{compact_evaluations.count}.5]

        # y-axis
        # set ylabel "#{outline[:observance].capitalize} for each sample (#{outline[:unit]})"
        #set logscale y
        #ytics norangelimit
        set ytics nomirror norotate autojustify #{y_min}, #{((y_max - y_min)/ 9.0).round(2)}, #{y_max}
        set yrange [#{y_min }:#{y_max}]

        # https://stackoverflow.com/questions/16736861/pointtype-command-for-gnuplot
        set style line 1 lc rgb '#0060ad' lt 1 lw 1 pt 0 pi -1 ps 1
        set style line 2 lc rgb '#515B00' lt 1 lw 1 pt 0 pi -1 ps 1
        set style boxplot nooutliers

        plot #{plot_commands}
      )
    end

    # '< paste -d, CSV1 CSV'

    def plot_evaluations(outline, compact_evaluations)
      # tics
      x_offset = 0
      x_tics = compact_evaluations.map do |e|
        x_offset += 1
        "\"#{e[:name]}\" \"#{x_offset}\""
      end.join(',')
      # samples lines, boxes
      x_offset = 0
      samples_csv = outline.result_file('samples.csv')
      sample_durations_csv = outline.result_file('sample_durations.csv')
      plot_commands = compact_evaluations.flat_map do |e|
        x_offset += 1
        # every ::2 => Start at row 2, first is header
        # using (1):2:(0.3) => explicit x value 1, y value column 2, with 0.3
        [
          # x value of samples should be equally distributed in [0 + i, 1 + i] based on the trial number.
          #
          "'#{samples_csv}' every ::2 using (#{x_offset + 0.28}):#{x_offset + 1} title columnheader with boxplot",
          #"'#{samples_csv}' every ::2 using (#{x_offset - 0.33} + $1 / #{evaluation.samples.count * 3.33}):($#{x_offset + 1} ) with line ls 2",
          "'< paste -d, #{sample_durations_csv} #{samples_csv}' every ::2 using (#{x_offset - 0.33} + ($#{x_offset + 1} / #{e[:max_sample_duration] * 3.33})):#{compact_evaluations.count + 1 + x_offset + 1} with line ls 1"
        ]

      end.join(',')
      [x_tics, plot_commands]
    end

    ##
    # Plot the total elapsed wall clock time (wct) on the x - axis and the
    # Runtime/Measure per sample on the y - axis
    # This way, you can see a phase change after the warmup time and when it happens
    ##
    def runtime_commands(outline, compact_evaluations)
      y_min = compact_evaluations.map { |e| e[:min_sample] }.min.round(2)
      y_max = compact_evaluations.map { |e| e[:max_sample] }.max.round(2)

      # samples lines, boxes
      samples_csv = outline.result_file('samples.csv')
      sample_durations_csv = outline.result_file('sample_durations.csv')
      total_wct_and_samples_csv = "< paste -d, #{sample_durations_csv} #{samples_csv}"

      evaluation_column = 1
      plot_commands = compact_evaluations.flat_map do |e|
        evaluation_column += 1
        ["'#{total_wct_and_samples_csv}' every ::2 using #{evaluation_column}:#{compact_evaluations.count + 1 + evaluation_column} with lines lw 2 title '#{e[:name]}'"] #with line ls 1
      end.join(',')

      default_plot_options(outline.test_file_name) +
      %Q(
        # The file to write to
        set output "#{outline.result_file('runtime_over_total_time.png')}"
        set border 2 front lt black linewidth 1.000 dashtype solid
        set boxwidth 0.5 absolute
        set style fill solid 0.50 border lt -1
        set pointsize 0.5

        # x-axis
        # set xlabel 'Total elapsed wall clock time (s)'
        set xtics nomirror norotate autojustify
        set xrange [0:#{outline[:measured_runtime]}]

        # y-axis
        # set ylabel "#{outline[:observance].capitalize} per sample (#{outline[:unit]})"
        set ytics nomirror norotate autojustify #{y_min}, #{((y_max - y_min) / 9.0).round(2)}, #{y_max}
        set yrange [#{y_min }:#{y_max}]

        #set style line 1 lc rgb '#0060ad' lt 1 lw 1 pt 0 pi -1 ps 1

        plot #{plot_commands}
      )
    end

    ##
    # Plot the total elapsed wall clock time (wct) on the x - axis and the
    # Memory footprint (RSS usage) per sample on the y - axis
    ##
    def memory_commands(outline, compact_evaluations)
      # memory lines
      memory_csv = outline.result_file('memory.csv')
      sample_durations_csv = outline.result_file('sample_durations.csv')
      total_wct_and_memory_csv = "< paste -d, #{sample_durations_csv} #{memory_csv}"

      y_min, y_max = CSV.read(memory_csv).drop(1).flatten.compact.map(&:to_f).minmax

      evaluation_column = 1
      plot_commands = compact_evaluations.flat_map do |e|
        evaluation_column += 1
        ["'#{total_wct_and_memory_csv}' every ::2 using #{evaluation_column}:#{compact_evaluations.count + 1 + evaluation_column} with lines lw 2 title '#{e[:name]}'"]
      end.join(',')

      default_plot_options(outline.test_file_name) +
      %Q(
        # The file to write to
        set output "#{outline.result_file('memory_over_total_time.png')}"
        set border 2 front lt black linewidth 1.000 dashtype solid
        set boxwidth 0.5 absolute
        set style fill solid 0.50 border lt -1
        set pointsize 0.5

        # x-axis
        set xtics nomirror norotate autojustify
        set xrange [0:#{outline[:measured_runtime]}]

        # y-axis
        set ytics nomirror norotate autojustify #{y_min.round(2)}, #{((y_max - y_min) / 9.0).round(2)}, #{y_max}
        set yrange [#{y_min}:#{y_max}]

        plot #{plot_commands}
      )
    end

    ##
    # Plot the response time of rails applications over time
    # x-axis: time series (second of the request start time)
    # y-axis: response time for each request (ms)
    ##
    def apache_bench_commands(view_name, path)
      default_plot_options(view_name) +
      %Q(
        # The file to write to
        set output "#{path}/#{view_name}.png"

        set datafile separator '\t'

        # Specify that the x-series data is time data
        set xdata time

        # Specify the *input* format of the time data
        set timefmt "%s"

        # Specify the *output* format for the x-axis tick labels
        set format x "%S"

        # Label the x-axis
        # set xlabel 'seconds'

        # Label the y-axis
        # set ylabel "response time (ms)"

        # Plot the data, start at the second row, x|y = columns 2 (seconds) and 5 (ttime)
        plot "#{path}/#{view_name}.tsv" every ::2 using 2:5 title 'response time over chronologically ordered requests' with points
      )
    end

    ##
    # PNG, CSV, Legend, 1:1
    ##

    def default_plot_options(title)
      %Q(
        # Output to a jpeg file
        set terminal png size 900,300

        # Set the aspect ratio of the graph
        set size 1, 1

        # The graph title
        # set title "#{title}"

        # Where to place the legend/key
        set key outside right top

        # Draw gridlines oriented on the y axis
        set grid y

        # Tell gnuplot to use comma as the delimiter instead of spaces (default)
        set datafile separator ','
      )
    end

    ##
    # Pipeline GNUPlot commands to the executable
    ##

    def gnu_plot(commands)
      IO.popen("gnuplot", "w") {|io| io.puts commands}
    end

  end
end