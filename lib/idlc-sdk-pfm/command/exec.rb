require 'idlc-sdk-pfm/command/base'
require 'mixlib/shellout'

module Pfm
  module Command
    class Exec < Pfm::Command::Base
      banner 'Usage: pfm exec SYSTEM_COMMAND'

      def run(params)
        exec(*params)
        raise 'Exec failed without an exception, your ruby is buggy' # should never get here
      end

      def needs_version?(_params)
        # Force version to get passed down to command
        false
      end

      def needs_help?(params)
        ['-h', '--help'].include? params[0]
      end
    end
  end
end
