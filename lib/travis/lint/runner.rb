require "pathname"
require "yaml"

require "travis/lint/linter"

module Travis
  module Lint

    class Runner
      def initialize(argv)
        if argv.empty?
          if File.exists?(".travis.yml")
            argv = [".travis.yml"]
          else
            show_help
          end
        end

        @travis_yml_file_paths = []
        argv.each do |arg|
          @travis_yml_file_paths << Pathname.new(arg).expand_path
        end
      end


      def run
        errors = false
        @travis_yml_file_paths.each do |travis_yml_file_path|
          check_that_travis_yml_file_exists!(travis_yml_file_path)
          check_that_travis_yml_file_is_valid_yaml!(travis_yml_file_path)

          if (issues = Linter.validate(self.parsed_travis_yml(travis_yml_file_path))).empty?
            puts "Hooray, #{travis_yml_file_path} seems to be solid!"
          else
            errors = true
            puts "#{travis_yml_file_path} has issues:"
            issues.each do |issue|
              puts "  Found an issue with the `#{issue[:key]}:` key:\n    #{issue[:issue]}"
            end
          end
          puts
        end
        exit(1) if errors
      end

      protected

      def check_that_travis_yml_file_exists!(travis_yml_file_path)
        quit("Cannot read #{travis_yml_file_path}: file does not exist or is not readable") unless File.exists?(travis_yml_file_path) &&
          File.file?(travis_yml_file_path) &&
          File.readable?(travis_yml_file_path)
      end

      def check_that_travis_yml_file_is_valid_yaml!(travis_yml_file_path)
        begin
          YAML.load_file(travis_yml_file_path)
        rescue ArgumentError, Psych::SyntaxError
          quit "#{travis_yml_file_path} is not a valid YAML file and thus will be ignored by Travis CI."
        end
      end

      def parsed_travis_yml(travis_yml_file_path)
        YAML.load_file(travis_yml_file_path)
      end

      def show_help
        puts <<-EOS
Usage:

    travis-lint [path to your .travis.yml]
      EOS

        exit(1)
      end

      def quit(message, status = 1)
        puts message
        puts

        exit(status)
      end
    end
  end
end
