require 'csv'
require 'fileutils'
require 'byebug'

class TCompare
  class Summarizer

    attr_reader :evaluations
    def initialize(compact_evaluations)
      @evaluations = compact_evaluations
    end

    def dump
      byebug
      write_to_csv([heading_row] + script_rows, 'results/scripts/summary.csv')
    end

    private

    def heading_row
      [''] + ([Interpreter.base] + Interpreter.versus).map {|i| i['name']}
    end

    def script_rows
      @evaluations.map do |script_name, evaluation|
        [script_name] + evaluation.map { |e|
          e[:serialization].nil? ? '1.0' : round_to(e[:serialization][5], 2)
          # Fixed index: median difference (see evaluation.rb)
        }
      end
    end

    def round_to(value, n)
      sprintf("%1.#{n}f", value)
    end

    def write_to_csv(rows, filepath)
      CSV.open(filepath, 'w', {encoding: 'UTF-8'}) do |csv|
        rows.each do |row|
          csv << row
        end
      end
    end
  end
end