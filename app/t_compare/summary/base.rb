require 'terminal-table/import'
require 'colorize'
require 'csv'

class TCompare
  module Summary
    class Base

      attr_reader :outline

      def initialize(outline)
        @outline = outline
      end

      def self.heading(string)
        separator = '#' * (string.length + 4)
        "\n" + separator + "\n# #{string} #\n" + separator + "\n"
      end

      private

      def heading(string)
        self.class.heading(string)
      end

      def align_rows(rows, alignments)
        rows.map do |row|
          row.each_with_index.map do |value, index|
            {value: value, alignment: alignments[index]}
          end
        end
      end

      def write_to_csv(rows, filepath)
        CSV.open(filepath, 'w') do |csv|
          rows.each do |row|
            csv << row
          end
        end
      end
    end
  end
end