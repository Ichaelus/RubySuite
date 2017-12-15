require 'byebug'
require 'byebug'
class TCompare
  module Evaluation
    class Base

      class << self
        def mean(samples)
          samples.inject(0.0, &:+) / samples.size
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
      end

      attr_accessor :samples, :p_tests, :memory_footprints, :iterations, :interpreter_name, :base, :outline, :sample_durations

      def initialize(interpreter, outline, base_evaluation = nil)
        @samples = []
        @sample_durations = []
        @p_tests = []
        @memory_footprints = []
        @iterations = 0
        @interpreter_name = interpreter['name']
        @base = base_evaluation
        @outline = outline
      end

      def trials_with_samples
        (TCompare::FIRST_TRIAL_WITH_PTEST..iterations).map {|i| at_trial(i)} # Starting at 1.
      end

      def run_and_add_p_test
        ttest = Statsample::Test::T::TwoSamplesIndependent.new(*base_and_own_sample_vectors)
        p_value = ttest.probability_not_equal_variance
        p_tests.push(p_value)
      end

      [:p_value, :diverged?, :mean, :median, :mean_difference, :median_difference, :superior_interpreter, :versus_is_superior?, :better_worse_or_equal, :sample, :sample_vector, :base_and_own_sample_vectors].each do |method|
        define_method(method) do |*args|
          last_trial.send(method, *args)
        end
      end

      def serialize
        return if @base.nil?
        [
          interpreter_name,
          better_worse_or_equal,
          p_value,
          median,
          @base.median,
          median_difference, # Do NOT change this order. Very sorry about the coding style, committing a paper results in hurry
          mean,
          @base.mean,
          mean_difference,
        ]
      end

      def serialize_trial_headers
        [
          [
           'Trial',
           "#{outline[:observance].capitalize} of #{@base.interpreter_name}",
           "#{outline[:observance].capitalize} of #{interpreter_name}",
           'p-value',
           'Superior'
          ]
        ]
      end

      def serialize_trials
        trials_with_samples.map(&:serialize)
      end

      def at_trial(i)
        Trial.new(i, self)
      end

      def to_s
        "#{outline.test_file_name} #{@base.interpreter_name} vs #{interpreter_name}"
      end

      def file_path_and_title
        "#{outline.result_dir}/#{to_s.gsub(' ', '_')}"
      end

      def summarize
        summary = Summary::Interim.new(outline, self)
        summary.print unless @base.nil?
        summary.export
      end

      def to_bare_minimum
        {
          name: interpreter_name,
          serialization: serialize,
          min_sample: samples.min,
          max_sample: samples.max,
          max_sample_duration: sample_durations.sort.last
        }
      end

      def restore
        @samples = CSV.read(outline.result_file('samples.csv'), headers: true)[interpreter_name].compact.map(&:to_f)
        @sample_durations = CSV.read(outline.result_file('sample_durations.csv'), headers: true)[interpreter_name].compact.map(&:to_f)
        @p_tests = CSV.read(outline.result_file('p_tests.csv'), headers: true)[interpreter_name].compact.map(&:to_f)
        @iterations = samples.count
        puts "Restored old values for #{interpreter_name}; delete result files to re-run the full evaluation"
      end

      private

      def last_trial
        at_trial(iterations)
      end

      def humanize(value)
        value.round(6)
      end

    end
  end
end