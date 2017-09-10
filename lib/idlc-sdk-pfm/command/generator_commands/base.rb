require "idlc-sdk-pfm/command/generator_commands"

module Pfm
  module Command
    module GeneratorCommands
      # ## Base
      #
      # Base class for `chef generate` subcommands. Contains basic behaviors
      # for setting up the generator context, detecting git, and launching a
      # chef converge.
      #
      # The behavior of the generators is largely delegated to a chef cookbook.
      # The default implementation is the `code_generator` cookbook in
      # pfm/skeletons/code_generator.
      class Base < Command::Base

        attr_reader :params
        attr_reader :errors

        options.merge!(SharedGeneratorOptions.options)

        def initialize(params)
          super()
          @params_valid = true
          @errors = []
          @params = params
        end

        def setup_context
        end

        def read_and_validate_params
          arguments = parse_options(params)
          case arguments.size
          when 1

          when 2

          else
            @params_valid = false
          end
        end

        def params_valid?
          @params_valid
        end
      end
    end
  end
end
