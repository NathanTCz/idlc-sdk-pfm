require 'idlc-sdk-pfm/command/base'
require 'mixlib/shellout'

module Pfm
  module Command
    class Build < Base
      banner 'Usage: pfm build BUILD_NAME [options]'

      option :app_release,
             short:        '-a VERSION',
             long:         '--app-release VERSION',
             description:  'Application Version Number to build',
             default:      ''

      option :build_version,
             short:        '-b VERSION',
             long:         '--build-version VERSION',
             description:  'override version number of build',
             default:      nil

      option :build_template,
             short:        '-t TEMPLATE',
             long:         '--build-template TEMPLATE',
             description:  'The Build Template to use. Defaults to build.json',
             default:      'build.json'

      option :build_metadata,
             short:        '-m METADATA_FILE',
             long:         '--build-metadata METADATA_FILE',
             description:  'The build metadata file to use. Defaults to \'metadata\'',
             default:      'metadata'

      option :build_number,
             short:        '-n NUMBER',
             long:         '--build-number NUMBER',
             description:  'Override the build number. Default is ENV::BUILD_NUMBER',
             default:      ENV['BUILD_NUMBER']

      def initialize
        super
        @params_valid = true
        @errors = []
      end

      def run(params)
        @params = params
        read_and_validate_params

        if params_valid?
          build_setup
          build
          # @workspace.cleanup causing bundler issues
          0
        else
          @errors.each { |error| err("Error: #{error}") }
          parse_options(params)
          msg(opt_parser)
          1
        end
      rescue BuildFailure => e
        err("ERROR: #{e.message}\n")
        1
      end

      def build
        # Zip the cookbooks for transfer
        Idlc::Workspace.zip_folder('./chef', "#{@workspace.tmp_dir}/cookbooks.zip")

        # Start the HTTP server to facilitate file transfers. This is to replace
        # WINRM for file transfers in Packer due to slowness. This function returns
        # the process id of the server instance.
        pid = Idlc::Build::Httpd.start(@workspace.tmp_dir)

        # #start will return twice when forking the HTTP server off, once for the
        # parent and once for the child. When the child return, the pid is nil. We want
        # to skip that run.
        unless pid.nil?
          # Pass some ENV vars for Packer
          @build_config.add_build_var_v2('aws_region', SETTINGS['AWS_REGION'])
          @build_config.add_build_var_v2('app_release', @config[:app_release])
          @build_config.add_build_var_v2('build_uuid', SecureRandom.uuid.to_s)
          @build_config.add_build_var_v2('build_number', @config[:build_number])
          @build_config.add_build_var_v2('httpd_server', Idlc::Build::Httpd.private_ip.to_s)
          @build_config.add_build_var_v2('httpd_port', ENV['HTTPD_PORT'])

          begin
            Packer::Binary.build("#{@build_config.dump_build_vars} #{@config[:build_template]}")
            Idlc::Build::Httpd.stop(pid)
            Dir.chdir(build_base_dir)
          rescue
            Idlc::Build::Httpd.stop(pid)
            Dir.chdir(build_base_dir)
            raise BuildFailure, 'The build finished with errors'
          end

        end

        Dir.chdir(build_base_dir)
      end

      def read_and_validate_params
        arguments = parse_options(@params)

        case arguments.size
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
    end
  end
end
