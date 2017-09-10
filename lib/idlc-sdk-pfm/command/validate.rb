require 'idlc-sdk-pfm/command/base'
require 'idlc-sdk-pfm/command/validator_commands'
require 'idlc-sdk-pfm/command/validator_commands/base'
require 'idlc-sdk-pfm/command/validator_commands/server_build'
require 'idlc-sdk-pfm/command/validator_commands/infrastructure'

module Pfm
  module Command
    class Validate < Base

      ValidatorCommand = Struct.new(:name, :class_name, :description)

      def self.validators
        @validators ||= []
      end

      def self.validator(name, class_name, description)
        validators << ValidatorCommand.new(name, class_name, description)
      end

      validator('server-build', :ServerBuild, 'Validate a server build repo')
      validator('infrastructure', :Infrastructure, 'Validate an infrastructure repo')

      def self.banner_headline
        <<-E
Usage: pfm validate VALIDATOR [options]
Available validators:
E
      end

      def self.validator_list
        justify_size = validators.map { |g| g.name.size }.max + 2
        validators.map { |g| "  #{g.name.to_s.ljust(justify_size)}#{g.description}" }.join("\n")
      end

      def self.banner
        banner_headline + validator_list + "\n"
      end

      # pfm validate app path/to/basename --skel=path/to/skeleton --example
      # pfm validate file name [path/to/cookbook_root] (inferred from cwd) --from=source_file

      def initialize(*args)
        super
      end

      def run(params)
        if validator_spec = validator_for(params[0])
          params.shift
          validator = ValidatorCommands.build(validator_spec.class_name, params)
          validator.run
        else
          msg(banner)
          1
        end
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
        # Pfm::Command::Base also handles this error in the same way, but it
        # does not have access to the correct option parser, so it cannot print
        # the usage correctly. Therefore, invalid CLI usage needs to be handled
        # here.
        err("ERROR: #{e.message}\n")
        msg(validator.opt_parser)
        1
      end

      def validator_for(arg)
        self.class.validators.find { |g| g.name.to_s == arg }
      end

      # In the Base class, this is defined to be true if any args match "-h" or
      # "--help". Here we override that behavior such that if the first
      # argument is a valid validator name, like `pfm validate server-build -h`,
      # we delegate the request to the specified validator.
      def needs_help?(params)
        return false if have_validator?(params[0])
        super
      end

      def have_validator?(name)
        self.class.validators.map { |g| g.name.to_s }.include?(name)
      end

    end
  end
end
