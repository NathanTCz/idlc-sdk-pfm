require "idlc-sdk-pfm/command/validator_commands"

module Pfm
  module Command
    module ValidatorCommands
      class ValidationError < StandardError; end

      class Base < Command::Base
        attr_reader :params
        attr_reader :errors

        options.merge!(SharedValidatorOptions.options)

        def initialize(params)
          super()
          @params_valid = true
          @errors = []
          @params = params
          @failure = false

          @reports_dir = "#{Pfm::Settings.new.config_directory}/tests/reports"
          @artifacts_dir = "#{Pfm::Settings.new.config_directory}/tests/artifacts"
        end

        def setup_context; end

        def read_and_validate_params
          arguments = parse_options(@params)

          case arguments.size
          when 0
            @params_valid = (@config[:validator_name] == 'infrastructure')

          when 1
            @params_valid = build_exists?

          when 2

          else
            @params_valid = false
          end
        end

        def params_valid?
          @params_valid
        end

        def use_circle_ci?
          @params.include?('-c') || @params.include?('--circle-ci')
        end

        def setup_artifacts_dirs
          if use_circle_ci?
            @reports_dir = ENV['CIRCLE_TEST_REPORTS']
            @artifacts_dir = ENV['CIRCLE_ARTIFACTS']
            return
          end

          FileUtils.mkdir_p(@reports_dir)
          FileUtils.mkdir_p(@artifacts_dir)
        end
      end
    end
  end
end
