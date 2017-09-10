require 'mixlib/cli'
require 'rbconfig'
require 'pathname'
require 'idlc-sdk-pfm/command/base'
require 'idlc-sdk-pfm/validator'

module Pfm
  module Command
    # ## SharedValidatorOptions
    #
    # These CLI options are shared amongst the validator commands
    module SharedValidatorOptions
      include Mixlib::CLI

      option :circle_ci,
             short:        '-c',
             long:         '--circle-ci',
             description: 'Use Circle Ci artifact output directories',
             boolean: true,
             default: false
    end

    # ## ValidatorCommands
    #
    # This module is the namespace for all subcommands of `pfm validate`
    module ValidatorCommands
      def self.build(class_name, params)
        const_get(class_name).new(params)
      end
    end
  end
end
