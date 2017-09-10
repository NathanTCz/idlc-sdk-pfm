require 'idlc-sdk-pfm/command/base'
require 'idlc-sdk-pfm/command/generator_commands'
require 'idlc-sdk-pfm/command/generator_commands/base'
require 'idlc-sdk-pfm/command/generator_commands/server_build'

module Pfm
  module Command
    class Generate < Base

      GeneratorCommand = Struct.new(:name, :class_name, :description)

      def self.generators
        @generators ||= []
      end

      def self.generator(name, class_name, description)
        generators << GeneratorCommand.new(name, class_name, description)
      end

      generator('server-build', :ServerBuild, 'Generate a server build repo')

      def self.banner_headline
        <<-E
Usage: pfm generate GENERATOR [options]
Available generators:
E
      end

      def self.generator_list
        justify_size = generators.map { |g| g.name.size }.max + 2
        generators.map { |g| "  #{g.name.to_s.ljust(justify_size)}#{g.description}" }.join("\n")
      end

      def self.banner
        banner_headline + generator_list + "\n"
      end

      # pfm generate app path/to/basename --skel=path/to/skeleton --example
      # pfm generate file name [path/to/cookbook_root] (inferred from cwd) --from=source_file

      def initialize(*args)
        super
      end

      def run(params)
        if generator_spec = generator_for(params[0])
          params.shift
          generator = GeneratorCommands.build(generator_spec.class_name, params)
          generator.run
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
        msg(generator.opt_parser)
        1
      end

      def generator_for(arg)
        self.class.generators.find { |g| g.name.to_s == arg }
      end

      # In the Base class, this is defined to be true if any args match "-h" or
      # "--help". Here we override that behavior such that if the first
      # argument is a valid generator name, like `pfm generate cookbook -h`,
      # we delegate the request to the specified generator.
      def needs_help?(params)
        return false if have_generator?(params[0])
        super
      end

      def have_generator?(name)
        self.class.generators.map { |g| g.name.to_s }.include?(name)
      end

    end
  end
end
