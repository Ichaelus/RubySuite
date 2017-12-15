class TCompare
  module Summary
    class Interim < Base

      attr_reader :evaluation

      def initialize(outline, evaluation)
        super(outline)
        @evaluation = evaluation
      end

      def print
        descriptions = compact_descriptions
        print_trials(descriptions)
        print_summary
      end

      def export
        puts heading("Exporting data to files located in: ./#{outline.result_dir}/")
        if evaluation.base.nil?
          create_outline_csvs
        else
          append_to_outline_csvs
        end
      end

      private

      def compact_descriptions
        compact_rows = []
        previous_row = [nil, nil, nil]
        evaluation.serialize_trials.each do |row|
          if row[3] == previous_row[3]
            # If the p-value is equal, remove the previous row
            # and display the last (equal) trial only
            compact_rows.pop
          end
          compact_rows << row
          previous_row = row
        end
        compact_rows
      end

      def print_trials(descriptions)
        puts Terminal::Table.new(
          :headings => evaluation.serialize_trial_headers,
          :rows => descriptions
        )
      end

      def print_summary
        if evaluation.diverged?
          puts heading("There is no performance difference").light_yellow
        else
          puts heading("#{evaluation.superior_interpreter} is performing better").light_yellow
        end
      end

      # Create CSVs for first interpreter

      def create_outline_csvs
        trials = trial_column(evaluation.iterations)
        write_to_csv(trials.zip(interpreter_samples), outline.result_file('samples.csv')) # Sample scores
        write_to_csv(trials.zip(interpreter_sample_durations), outline.result_file('sample_durations.csv')) # Sample wall clock times
        write_to_csv(trials.zip(interpreter_memory_footprint), outline.result_file('memory.csv')) # Memory usage per trial
        write_to_csv(p_test_trial_rows, outline.result_file('p_tests.csv')) # P-Test scores, empty for now
      end

      def trial_column(trial_count)
        ['Trial'] + (1..trial_count).to_a
      end

      def interpreter_samples
        [evaluation.interpreter_name] + evaluation.samples
      end

      def interpreter_sample_durations
        [evaluation.interpreter_name] + evaluation.sample_durations
      end

      def interpreter_memory_footprint
        [evaluation.interpreter_name] + evaluation.memory_footprints
      end

      def p_test_trial_rows
        [['Trial'] + (TCompare::FIRST_TRIAL_WITH_PTEST..evaluation.iterations).to_a].transpose
      end

      # Append to CSVs for each other interpreter

      def append_to_outline_csvs
        append_to_csv('samples.csv', interpreter_samples)
        append_to_csv('sample_durations.csv', interpreter_sample_durations)
        append_to_csv('memory.csv', interpreter_memory_footprint)
        append_to_csv('p_tests.csv', interpreter_p_tests)
      end

      def append_to_csv(filename, new_column)
        existing_cols = CSV.read(outline.result_file(filename)).transpose
        old_trials = existing_cols.shift # Remove existing trial column, may be outdated
        new_max_trials = [new_column.count, (existing_cols.last || old_trials).count].max - 1
        new_columns = trial_column(new_max_trials).zip(*existing_cols, new_column)
        write_to_csv(new_columns, outline.result_file(filename))
      end

      def interpreter_p_tests
        [evaluation.interpreter_name] + evaluation.p_tests
      end

    end
  end
end
