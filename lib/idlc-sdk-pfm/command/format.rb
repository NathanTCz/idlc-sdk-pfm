require 'idlc-sdk-pfm/command/base'
require 'mixlib/shellout'

module Pfm
  module Command
    class Format < Base
      banner 'Usage: pfm format [options]'

      def initialize
        super
        @params_valid = true
        @errors = []
      end

      def run(params)
        @params = params
        read_and_validate_params

        if params_valid?
          fmt
          # @workspace.cleanup causing bundler issues
          0
        else
          @errors.each { |error| err("Error: #{error}") }
          parse_options(params)
          msg(opt_parser)
          1
        end
      rescue DeploymentFailure => e
        err("ERROR: #{e.message}\n")
        1
      end

      def fmt
        raise InvalidRepository, 'This doesn\'t look like a valid infrastructure repository' unless File.directory? "#{inf_base_dir}/tf"
        tf_paths = %W[#{inf_base_dir}/tf lib/tf/modules]

        begin
          tf_paths.each do |path|
            # Format the file to a canonical syntax
            Terraform::Binary.fmt(path)
          end
        rescue
          raise DeploymentFailure, 'Finished with errors'
        end
      end

      def read_and_validate_params
        arguments = parse_options(@params)

        case arguments.size
        when 0
          @params_valid = true
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
