require 'idlc-sdk-pfm/command/base'
require 'mixlib/shellout'

module Pfm
  module Command
    class Plan < Base
      banner 'Usage: pfm plan [options]'

      option :app_release,
             short:        '-a VERSION',
             long:         '--app-release VERSION',
             description:  'Application Version Number to Deploy',
             default:      ''

      option :server_build,
             short:        '-b NUMBER',
             long:         '--server-build NUMBER',
             description:  'Server Build Number to Deploy',
             default:      ENV['SERVER_BUILD']

      option :landscape,
             short:        '-l',
             long:         '--landscape',
             description:  'Format the output with the terraform_landscape gem',
             boolean:      true,
             default:      false

      def initialize
        super
        @params_valid = true
        @errors = []
      end

      def run(params)
        @params = params
        read_and_validate_params

        if params_valid?
          deploy_setup
          plan
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

      def plan
        begin
          Terraform::Binary.plan(@workspace.tmp_dir) unless @config[:landscape]
          Terraform::Binary.plan("#{@workspace.tmp_dir} | landscape") if @config[:landscape]
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
