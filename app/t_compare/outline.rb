require 'ohai'
require 'json'

class TCompare
  class Outline

    class << self

      def scripts
        JSON.parse File.read('scripts.json')
      end

    end

    def initialize(options)
      @outline = options
      @outline[:start_time] = Time.now.to_s
    end

    def reinitialize(options)
      if options.any?
        puts TCompare::Summary::Base.heading("Changing the outline")
        options.each do |attribute, value|
          @outline[attribute.to_sym] = value
        end
        puts Terminal::Table.new(
          headings: %w(Attribute Value),
          rows: options.to_a
        )
      end
      @outline[:start_time] = Time.now.to_s
    end

    def [](attribute)
      @outline[attribute]
    end

    def []=(attribute, value)
      @outline[attribute] = value
    end

    def serialize
      system = Ohai::System.new
      system = system.all_plugins(["lsb", "kernel", "cpu", "memory"])
      [
        %w[Attribute Value],
          ['Test-Script', @outline[:test_file]],
          ['Observed attribute', @outline[:observance].capitalize],
          ['Higher value is better', @outline[:higher_is_better]],
          ['Base Interpreter', TCompare::Interpreter.base['name']],
          ['Threshold for the p-value', @outline[:p_threshold]],
          ['Input size', @outline[:input_size]],
          ['Warmup runs', @outline[:warmup]],
          ['Trial runs', @outline[:trials]],
          ['Runtime measured (s)', @outline[:measured_runtime]],
          ['Start-Time of the Experiment', @outline[:start_time]],
          ['End-Time of the Experiment', Time.now.to_s],
          ['Evaluating interpreter', `ruby -v`.strip],
          ['Operating system', system["lsb"]["description"]],
          ['Processor', system["cpu"]["0"]["model_name"].gsub(/\s+/, ' ').strip],
          ['Physical cores', system["cpu"]["cores"]],
          ['Total cores', system["cpu"]["total"]],
          ['Memory (total)', system["memory"]["total"]],
          ['Memory (free)', system["memory"]["free"]],
      ]
    end

    def result_file(name)
      "#{result_dir}/#{test_file_name}_#{name}"
    end

    def result_dir
      dir! "results/scripts/#{test_file_name}"
    end

    def test_file_name
      @outline[:test_file].split("/").last.split(".").first
    end

    private

    def self.ignore_commented_out_lines(lines)
      lines.select { |path| path[0] != '#' }
    end

    def dir!(path)
      Dir.mkdir(path) unless File.exists?(path)
      path
    end
  end
end