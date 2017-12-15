require 'byebug'

class TCompare
  module Evaluation
    class Trial < Base

      attr_reader :trial, :evaluation

      def initialize(trial, evaluation)
        @trial = trial
        @evaluation = evaluation
      end

      def sample
        evaluation.samples[trial - 1]
      end

      def all_samples
        evaluation.samples.take(trial)
      end

      def median
        humanize self.class.median(all_samples)
      end

      def mean
        humanize self.class.mean(all_samples)
      end

      def median_difference
        if evaluation.outline[:higher_is_better]
          humanize(median / base.median)
        else
          humanize(base.median / median)
        end
      end

      def mean_difference
        if evaluation.outline[:higher_is_better]
          humanize(mean / base.mean)
        else
          humanize(base.mean / mean)
        end
      end

      def superior_interpreter
        if diverged?
          'equal'
        else
          better_than_base? ? evaluation.interpreter_name : evaluation.base.interpreter_name
        end
      end

      def diverged?
        (p_value >= evaluation.outline[:p_threshold])
      end

      def better_than_base?
        mean_difference > 1 && median_difference > 1
      end

      def better_worse_or_equal
        if diverged?
          'equal'
        else
          better_than_base? ? 'better' : 'worse'
        end
      end

      def p_value
        # The current p_test or, if the sample size diverge, the last p_test
        humanize(evaluation.p_tests[trial - TCompare::FIRST_TRIAL_WITH_PTEST] || evaluation.p_tests.last)
      end 

      def serialize
        [trial, base.sample, sample, p_value, superior_interpreter]
      end

      def sample_vector
        named_vector(all_samples, evaluation.interpreter_name)
      end

      def base_and_own_sample_vectors
        [sample_vector, base.sample_vector]
      end

      private

      def base
        evaluation.base.at_trial(trial)
      end

      def named_vector(array, name)
        vector = array.flatten.to_vector
        vector.name = name
        vector
      end
    end
  end
end