module Pfm
  # == +PFM+ Settings
  # Top level settings defined and loaded here. This class loads the user config file
  # located at +.pfm/config+
  #
  # +AWS_REGION+ <em>default -> 'us-east-1'</em>
  #
  # * The AWS region to work in. This will eventually become the AWS_REGION environment variable and can be used with other AWS API operations.
  #
  # +RUBOCOP_RULES_FILE+ <em>default -> '.rubocop.yml'</em>
  #
  # * Set the path to the global +.rubocop.yml+ rules file. This file will be used for all server builds when running syntax checks.
  #
  # +FOODCRITIC_RULES_FILE+ <em>default -> '.foodcritic'</em>
  #
  # * Set the path to the global +.foodcritic+ rules file. This file will be used for all server builds when running semantics checks.
  #
  # +BUILD_BASE_DIR+ <em>default -> 'builds'</em>
  #
  # * Set the root path to the builds directory. This should be where top level server builds are located. Ex:
  #     .
  #     ├── builds
  #     │   ├── app-axpdb
  #     │   └── app-axpwa
  #
  # +INF_BASE_DIR+ <em>default -> 'inf'</em>
  #
  # * Set the path to the top level infrastructure directory. Ex:
  #     .
  #     ├── inf
  #     │   ├── env
  #     │   ├── tasks
  #     │   └── tf
  #
  # +PUBLISH_BUCKET+ <em>default -> ''</em>
  #
  # * The top level bucket where deployment packages are stored in S3.
  #
  # +PUBLISH_PREFIX+ <em>default -> ''</em>
  #
  # * The prefix to the deployment package storage location. Ex:
  #   +s3://PUBLISH_BUCKET/PUBLISH_PREFIX/package.name+
  #
  # +PACKER_VERSION+ <em>default -> 'default from packer/binary'
  #
  # * The version of Hashicorp Packer to use for builds
  #
  # +TERRAFORM_VERSION+ <em>default -> 'default from terraform/binary'
  #
  # * The version of Hashicorp Terraform to use for deployments
  #
  # Note that if you change these settings from the default, be sure you commit
  # the +.pfm/config+ file.
  #
  # == Example Configuration File
  # An example +.pfm/config+ file might look like this:
  #     ---
  #     AWS_REGION: 'us-east-1'
  #     RUBOCOP_RULES_FILE: '.pfm/.rubocop.yml'
  #     FOODCRITIC_RULES_FILE: '.pfm/.foodcritic'
  #     BUILD_BASE_DIR: 'builds'
  #     INF_BASE_DIR: 'inf'
  #     PUBLISH_BUCKET: 'dev-publish'
  #     PUBLISH_PREFIX: 'axp'
  #     PACKER_VERSION: '1.0.4'
  #     TERRAFORM_VERSION: '0.8.7'
  class Settings
    # Defines an individual setting
    class Setting
      attr_reader :value

      def initialize(value, required = false)
        @value = value
        @required = required
      end

      def required?
        @required
      end

      def defined?
        !@value.nil?
      end

      def to_s
        @value.to_s
      end
    end

    # @return [Map] returns the map of Pfm::Settings::Setting objects
    attr_reader :settings
    attr_reader :config_directory
    attr_reader :run_dir

    def initialize(expand = false)
      @run_dir = Dir.pwd
      @config_directory = config_dir
      @expand = expand

      @settings = {}

      # Required
      @settings['AWS_REGION'] = Setting.new('us-east-1', true)
      @settings['RUBOCOP_RULES_FILE'] = Setting.new('.rubocop.yml', true)
      @settings['FOODCRITIC_RULES_FILE'] = Setting.new('.foodcritic', true)
      @settings['BUILD_BASE_DIR'] = Setting.new('builds', true)
      @settings['INF_BASE_DIR'] = Setting.new('inf', true)
      @settings['PACKER_VERSION'] = Setting.new(::Packer::Binary.config.version, true)
      @settings['TERRAFORM_VERSION'] = Setting.new(::Terraform::Binary.config.version, true)

      # Optional Defaults
      @settings['PUBLISH_BUCKET'] = Setting.new('')
      @settings['PUBLISH_PREFIX'] = Setting.new('')

      load_config
    end

    # load the config file and resolve file paths if set
    def load_config
      if config_exists?
        require 'yaml'
        YAML.load_file(config_file).each do |key, value|
          msg("WARNING: unrecognized config key: '#{key}'") unless @settings.key? key
          next unless @settings.key? key

          required = @settings[key].required?
          @settings[key] = Setting.new(value, required)
        end

        # Also load each setting into the environment
        @settings.each { |key, setting| ENV[key] = setting.value }

        # Resolve paths if set
        resolve_paths if @expand
      else
        create_config
        load_config
      end
    end

    # Saves a new configuration to disk
    # @param settings [Map<Pfm::Settings::Setting>] a new map of Pfm::Settings::Setting objects
    def save_config(settings)
      @settings = settings

      write_config
    end

    # returns a simple map of Pfm::Settings.settings[key] => Pfm::Settings.setting[key].to_s
    # @return [Map<String>]
    def settings_strings
      map = {}
      @settings.each do |key, setting|
        map[key] = setting.to_s
      end

      map
    end

    private

    # create the config directory and file if they don't already exist
    def create_config
      return if config_exists?

      FileUtils.mkdir_p config_dir
      FileUtils.touch config_file

      write_config
    end

    # expands variables like '.' and '~' in settings values paths
    def resolve_paths
      @settings.each do |key, setting|
        required = @settings[key].required?
        @settings[key] = Setting.new(File.realpath(setting.value), required) if File.exist? setting.value
      end
    end

    # writes the @settings attribute to disk
    def write_config
      config_string = '---'

      @settings.each do |key, setting|
        config_string += "\n#{key}: '#{setting.value}'"
      end

      config_string += "\n"

      File.open(config_file, 'w') { |file| file.write(config_string) }
    end

    def config_exists?
      File.exist? config_file
    end

    def config_dir
      "#{@run_dir}/.pfm"
    end

    def config_file
      "#{config_dir}/config"
    end
  end
end
