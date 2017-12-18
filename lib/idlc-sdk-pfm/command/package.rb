require 'idlc-sdk-pfm/command/base'
require 'mixlib/shellout'

module Pfm
  module Command
    class Package < Base
      banner 'Usage: pfm package [options]'

      option :application_name,
             long:         '--application-name NAME',
             description:  'Application Name',
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
          package
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

      def package
        raise InvalidRepository, 'This doesn\'t look like a valid infrastructure repository' unless File.directory? "#{inf_base_dir}/tf"

        workspace = Idlc::Workspace.new

        workspace.flatten("#{inf_base_dir}/tf", 'tf')
        workspace.add('lib/')
        workspace.add('ci/dsl')
        workspace.add('backend.tf') if File.exist? 'backend.tf'

        dest_zip = "./.pfm/#{@config[:application_name]}.#{REPO_VERSION}.infra.zip"
        FileUtils.rm_rf(dest_zip) if File.exist? dest_zip
        Idlc::Workspace.zip_folder(workspace.tmp_dir, dest_zip)
        msg("packaged to #{dest_zip}")
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
