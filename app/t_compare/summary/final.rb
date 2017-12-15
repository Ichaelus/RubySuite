class TCompare
  module Summary
    class Final < Base

      attr_reader :compact_evaluations

      def initialize(outline, compact_evaluations)
        super(outline)
        @compact_evaluations = compact_evaluations
      end

      def print
        print_final_summary
        puts heading("Exporting data to files located in: ./#{outline.result_dir}/")
        write_outline_to_csv
        write_summary_to_csv
        Plot.box_plots_with_samples(outline, @compact_evaluations)
      end

      private

      def print_final_summary
        print_outlines
        print_test_results
      end

      def print_outlines
        puts heading("Experiment outlines")
        alignments = [:left, :left]
        rows = outline.serialize
        puts Terminal::Table.new(
          :headings => align_rows([rows.shift], alignments),
          :rows => align_rows(rows, alignments),
        )
      end

      def print_test_results
        puts heading("T-Test results for #{outline.test_file_name}")
        alignments = [:left, :left, :right, :right, :right, :right, :right]
        puts Terminal::Table.new(
          :headings => serialize_evaluations_headers,
          :rows => align_rows(evaluations_without_base.map {|e| e[:serialization]}, alignments)
        ).to_s.light_yellow
      end

      def write_outline_to_csv
        write_to_csv(outline.serialize, outline.result_file('outline.csv'))
      end

      def write_summary_to_csv
        rows = [serialize_evaluations_headers] + evaluations_without_base.map {|e| e[:serialization]}
        write_to_csv(rows.transpose, outline.result_file('summary.csv'))
      end

      def evaluations_without_base
        compact_evaluations.drop(1)
      end

      def serialize_evaluations_headers
        [
          'Interpreter',
          "vs. #{compact_evaluations.first[:name]} (Base)",
          'p-value',
          "#{outline[:observance].capitalize} median",
          "#{outline[:observance].capitalize} median (Base)",
          "#{outline[:observance].capitalize} median (difference)",
          "#{outline[:observance].capitalize} mean",
          "#{outline[:observance].capitalize} mean (Base)",
          "#{outline[:observance].capitalize} mean (difference)",
        ]
      end
    end
  end
end