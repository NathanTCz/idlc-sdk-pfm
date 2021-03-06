require 'idlc-sdk-pfm/command/base'
require 'mixlib/shellout'
require 'aws-sdk-s3'
require 'json'
require 'colorize'

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

        # tag git repo with version number.
        begin
          system("git tag -am 'v#{REPO_VERSION}' v#{REPO_VERSION} &>/dev/null") || raise
          msg("Tagged v#{REPO_VERSION}".colorize(:green))
        rescue
          msg("Tag v#{REPO_VERSION} has already been created... skipping.".colorize(:green))
        end

        begin
          system('git push --follow-tags &>/dev/null') || raise
          msg('Pushed git tags.'.colorize(:green))
        rescue
          err('Failed to push tags.'.colorize(:red))
        end

        workspace = Idlc::Workspace.new

        workspace.flatten("#{inf_base_dir}/tf", 'tf')
        workspace.add('lib/')
        workspace.add('.pfm/config') if File.exist? '.pfm/config'
        workspace.add('backend.tf') if File.exist? 'backend.tf'
        workspace.add('infraspec.yml') if File.exist? 'infraspec.yml'

        package_name = "#{@config[:application_name]}.#{REPO_VERSION}.infra.zip"
        dest_zip = "./.pfm/#{package_name}"
        FileUtils.rm_rf(dest_zip) if File.exist? dest_zip
        Idlc::Workspace.zip_folder(workspace.tmp_dir, dest_zip)
        msg("packaged to #{dest_zip}".colorize(:green))

        # upload to s3
        s3 = Aws::S3::Resource.new(region: SETTINGS['AWS_REGION'])
        bucket_name = Idlc::SERVICES[SETTINGS['AWS_REGION']]['build']['publish_bucket']

        obj = s3.bucket(bucket_name).object(package_name)
        obj.upload_file(dest_zip)
        msg('Pushed package to S3.'.colorize(:green))

        # register with Orchestrate Build
        raise InvalidRepository, 'Missing configuration.schema.json file in root.' unless File.exist? 'configuration.schema.json'
        client = Idlc::AWSRestClient.new()

        request = {
          service: 'build',
          method: 'PUT',
          path: '/builds',
          body: {
            application_name: @config[:application_name],
            revision: REPO_VERSION,
            artifact_path: "s3://#{bucket_name}/#{package_name}",
            configuration_schema: JSON.parse(File.read('configuration.schema.json'))
          }
        }

        response = client.fetch(request.to_json)
        msg("Registered #{@config[:application_name]} #{REPO_VERSION} with Orchestrate.".colorize(:green))
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
