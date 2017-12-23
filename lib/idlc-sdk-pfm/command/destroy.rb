require 'idlc-sdk-pfm/command/base'
require 'mixlib/shellout'

module Pfm
  module Command
    class Destroy < Base
      banner 'Usage: pfm destroy [options]'

      option :config_file,
            short:        '-c FILE',
            long:         '--config-file FILE',
            description:  'Optional environment metadata file',
            default:      nil

      option :working_dir,
            short:        '-d DIR',
            long:         '--dir DIR',
            description:  'Optional directory of infrastructure configuration to use',
            default:      ''

      def initialize
        super
        @params_valid = true
        @errors = []
      end

      def run(params)
        @params = params
        read_and_validate_params

        if params_valid?
          if (@config[:config_file])
            deploy_setupv2
            destroy(@config[:working_dir])
          else
            deploy_setup
            destroy(@workspace.tmp_dir)
          end
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

      def destroy(dir)
        Idlc::Deploy::Config.add_deployment_var('build', ENV['SERVER_BUILD'])
        Idlc::Deploy::Config.add_deployment_var('app_release', 'null')

        Terraform::Binary.destroy("#{dir}")
      rescue
        raise DeploymentFailure, 'Finished with errors'
      end

      def read_and_validate_params
        arguments = parse_options(@params)

        @params_valid = case arguments.size
                        when 0
                          true
                        else
                          false
                        end
      end

      def params_valid?
        @params_valid
      end
    end
  end
end
