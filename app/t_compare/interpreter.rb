require 'memoizer'
require 'json'
class TCompare
  class Interpreter
    class << self
      include Memoizer

      def base
        all_interpreters['base']
      end

      def versus
        all_interpreters['versus']
      end

      def bundle
        puts TCompare::Summary::Base.heading("Bundling the executing interpreter #{RUBY_VERSION}")
        system 'ruby -S bundle update'
        ([base] + versus).uniq.each do |interpreter|
          puts TCompare::Summary::Base.heading("Bundling the evaluated interpreter #{interpreter['name']}")

          with_bundler_installed(interpreter) do
            system ruby_as(interpreter, 'bundle --gemfile=VersusGemfile')
          end
        end
      end


      def command_as(interpreter, command)
        "eval \"$(rbenv init -)\" && rbenv shell #{interpreter['rbenv-command']} && #{interpreter['environment']} #{command}"
      end

      def ruby_as(interpreter, command)
        command_as(interpreter, "ruby #{interpreter['parameters']} -S #{command}")
      end

      def inline_ruby_as(interpreter, command)
        command_as(interpreter, "ruby #{interpreter['parameters']} -e #{command}")
      end

      private

      def with_bundler_installed(interpreter)
        unless `gem list`.lines.grep(/^bundler \(.*\)/)
          puts "installing bundler first.."
          system command_as(interpreter, 'gem install bundler')
        end
        yield
      end

      def all_interpreters
        JSON.parse File.read('interpreters.json')
      end
      memoize :all_interpreters

    end
  end
end
