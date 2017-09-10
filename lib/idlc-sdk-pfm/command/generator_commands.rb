require 'mixlib/cli'
require 'rbconfig'
require 'pathname'
require 'idlc-sdk-pfm/command/base'
require 'idlc-sdk-pfm/generator'

module Pfm
  module Command
    # ## SharedGeneratorOptions
    #
    # These CLI options are shared amongst the generator commands
    module SharedGeneratorOptions
      include Mixlib::CLI

      # You really want these to have default values, as
      # they will likely be used all over the place.
      # option :verbose,
      #        short:        '-V',
      #        long:         '--verbose',
      #        description:  'Show detailed output from the generator',
      #        boolean:      true,
      #        default:      false
    end

    # ## GeneratorCommands
    #
    # This module is the namespace for all subcommands of `pfm generate`
    module GeneratorCommands
      def self.build(class_name, params)
        const_get(class_name).new(params)
      end
    end
  end
end
