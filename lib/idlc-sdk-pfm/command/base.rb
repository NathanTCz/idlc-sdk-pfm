require 'mixlib/cli'
require 'idlc-sdk-pfm/helpers'
require 'securerandom'
require 'json'

module Pfm
  module Command
    class Base
      include Mixlib::CLI
      include Pfm::Helpers

      class InvalidRepository < StandardError; end
      class BuildFailure < StandardError; end
      class DeploymentFailure < StandardError; end

      option :help,
             short: '-h',
             long: '--help',
             description: 'Show this message',
             boolean: true

      option :version,
             short: '-v',
             long: '--version',
             description: 'Show pfm version',
             boolean: true

      option :verbose,
             short:        '-V',
             long:         '--verbose',
             description:  'Show detailed output',
             boolean:      true,
             default:      false

      def initialize
        super

        @workspace = Idlc::Workspace.new
      end

      #
      # optparser overwrites -h / --help options with its own.
      # In order to control this behavior, make sure the default options are
      # handled here.
      #
      def run_with_default_options(params = [])
        if needs_help?(params)
          msg(opt_parser.to_s)
          0
        elsif needs_version?(params)
          msg("Pfm Version: #{Pfm::VERSION}")
          0
        else
          ENV['DEBUG'] = 'true' if verbose?(params)
          run(params)
        end
      rescue NameError => e
        err("ERROR: #{e.message}\n")
        1
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
        err("ERROR: #{e.message}\n")
        msg(opt_parser)
        1
      rescue Idlc::Build::MissingMetadataFile, Idlc::Build::MissingRequiredMetadataAttribute, InvalidRepository => e
        err("ERROR: #{e.message}\n")
        1
      ensure
        @workspace.cleanup unless @workspace.empty?
      end

      def build_setup
        Packer::Binary.configure do |config|
          config.version = SETTINGS['PACKER_VERSION']
          config.download_path = "/tmp/#{SecureRandom.uuid}"
        end

        @build_config = Idlc::Build::Config.new(SETTINGS['AWS_REGION'])
        @workspace.add(build_base_dir)

        build_dir = "#{@workspace.tmp_dir}/#{build_base_dir}".freeze

        msg("Using build template: Build::#{@params.first}::#{@config[:build_template]}::#{@config[:build_metadata]}")

        # Include build metadata
        @build_metadata = Idlc::Build::Metadata.new(@params.first, @config[:build_metadata])

        # load the rest of the metadata
        @build_metadata.load

        # load version from command line if specified
        @build_metadata.attributes['version'] = Idlc::Build::Metadata::MetadataAttribute.new(@config[:build_version], true) unless @config[:build_version].nil?

        # check metadata requirements
        @build_metadata.requirements_satisfied?

        msg("Template Version: #{@build_metadata.attributes['version'].value}")

        @build_metadata.attributes.each do |key, att|
          # load metadata file as packer user vars
          @build_config.add_build_var_v2(key, att.value)
        end

        # Copy over the base template and auxillary files for Packer
        tpl = Idlc::Build::Template.new(
          @build_metadata.attributes,
          "#{build_dir}/build.json"
        )
        tpl.write

        # copy auxiliary files
        system("cp -a #{templates_dir}/files #{build_dir}")

        Dir.chdir(build_dir)
      end

      def deploy_setup
        Terraform::Binary.configure do |config|
          config.version = SETTINGS['TERRAFORM_VERSION']
          config.download_path = "/tmp/#{SecureRandom.uuid}"
        end

        raise InvalidRepository, 'This doesn\'t look like a valid infrastructure repository' unless File.directory? "#{inf_base_dir}/tf"
        config = Idlc::Deploy::Config.new(SETTINGS['AWS_REGION'])

        config.parse("#{inf_base_dir}/env/config/default.yml") if File.exist? "#{inf_base_dir}/env/config/default.yml"

        if ENV['PROD'] == 'true' || ENV['PROD'] == '1'
          config.parse("#{inf_base_dir}/env/config/prod.yml")
        else
          config.parse("#{inf_base_dir}/env/config/devtest.yml")
        end

        config.parse("#{inf_base_dir}/env/size/#{ENV['SIZE']}.yml") if File.exist? "#{inf_base_dir}/env/size/#{ENV['SIZE']}.yml"

        inf_conf_file = 'inf.config.yml'

        # For unit tests
        inf_conf_file = 'inf.config.example.yml' unless File.exist? inf_conf_file
        config.parse(inf_conf_file)

        bucket_name = Idlc::Deploy::Config.get_deployment_var('tfstate_bucket')
        sub_bucket = "#{Idlc::Deploy::Config.get_deployment_var('job_code')}"\
          "#{Idlc::Deploy::Config.get_deployment_var('job')}"\
          "-#{Idlc::Deploy::Config.get_deployment_var('env')}".freeze

        # Pass some ENV vars for Terraform
        Idlc::Deploy::Config.add_deployment_var('environment_key', sub_bucket)
        Idlc::Deploy::Config.add_deployment_var('version', REPO_VERSION)
        Idlc::Deploy::Config.add_deployment_var('major_minor', Idlc::Utility.major_minor(REPO_VERSION))
        Idlc::Deploy::Config.add_deployment_var('major_minor_patch', Idlc::Utility.major_minor_patch(REPO_VERSION))
        Idlc::Deploy::Config.add_deployment_var('build', @config[:server_build])
        Idlc::Deploy::Config.add_deployment_var('app_release', @config[:app_release])

        Idlc::Deploy::Keypair.generate("#{inf_base_dir}/env/kp")
        @workspace.flatten("#{inf_base_dir}/tf", 'tf')
        @workspace.add("#{inf_base_dir}/env/kp")
        @workspace.add('lib/tf/modules')

        config.configure_state(bucket_name, sub_bucket, @workspace.tmp_dir)
      end

      def deploy_setupv2
        Terraform::Binary.configure do |config|
          config.version = SETTINGS['TERRAFORM_VERSION']
          config.download_path = "/tmp/#{SecureRandom.uuid}"
        end

        # Create dynamic variables file for terraform based on config
        keys = {}
        vars_file = ''

        env_metadata = JSON.parse(open(@config[:config_file]).read)
        ['account', 'environment', 'ec2', 'application'].each do |section|
          env_metadata[section].each do |key, value|
            # skip dups
            next unless keys[key].nil?

            # replace null with empty string
            value = '' if value.nil?

            # skip lists and maps
            next unless (value.instance_of? String)

            # add to vars file and record key for dups
            keys[key] = 'parsed'
            vars_file += <<~EOH
              variable "#{key}" {}

            EOH

            # load value into envrionment
            Idlc::Deploy::Config.add_deployment_var(key, value)
          end
        end

        # write vars file
        File.open("#{config[:working_dir]}/#{env_metadata['environment_key']}-tfvars.tf", 'w') { |file| file.write(vars_file) }

        # Pass some extra vars for Terraform
        Idlc::Deploy::Config.add_deployment_var('aws_region', SETTINGS['AWS_REGION'])
        Idlc::Deploy::Config.add_deployment_var('environment_key', env_metadata['environment_key'])
        Idlc::Deploy::Config.add_deployment_var('version', env_metadata['environment']['inf_version'])
        Idlc::Deploy::Config.add_deployment_var('app_release', @config[:app_release])
        ENV['APP_RELEASE'] = @config[:app_release]

        Idlc::Deploy::Keypair.generate("#{@config[:working_dir]}/env/kp")

        config = Idlc::Deploy::Config.new(SETTINGS['AWS_REGION'])
        config.configure_state(
          env_metadata['account']['tfstate_bucket'],
          env_metadata['environment_key'],
          @config[:working_dir]
        )
      end

      def templates_dir
        "#{__dir__}/templates/#{@build_metadata.attributes['build_stage'].value}"
      end

      def build_base_dir
        "#{SETTINGS['BUILD_BASE_DIR']}/#{@params.first}"
      end

      def inf_base_dir
        SETTINGS['INF_BASE_DIR']
      end

      def build_dir
        "#{@workspace.tmp_dir}/#{build_base_dir}".freeze
      end

      def build_exists?
        return true if Dir.exist? build_base_dir

        # doesn't exist
        @errors.push("Build::#{@params.first} doesnt exist")
        false
      end

      def needs_help?(params)
        params.include?('-h') || params.include?('--help')
      end

      def needs_version?(params)
        params.include?('-v') || params.include?('--version')
      end

      def verbose?(params)
        params.include?('-V') || params.include?('--verbose')
      end
    end
  end
end
