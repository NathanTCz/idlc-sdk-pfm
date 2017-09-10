require 'idlc-sdk-pfm/command/base'
require 'mixlib/shellout'

module Pfm
  module Command
    class Configure < Pfm::Command::Base
      banner 'Usage: pfm configure SYSTEM_COMMAND'

      def run(params)
        current_set = Pfm::Settings.new
        new_settings = {}

        current_set.settings.each do |key, setting|
          print("#{key} [#{setting.value}]: ")
          stdin = STDIN.gets.chomp.strip

          required = setting.required?
          new_value = setting.value
          new_value = stdin unless null?(stdin)

          new_settings[key] = Pfm::Settings::Setting.new(new_value, required)
        end

        current_set.save_config(new_settings)
      end

      def needs_version?(_params)
        # Force version to get passed down to command
        false
      end

      def null?(value)
        value.nil? || value == ''
      end

      def needs_help?(params)
        ['-h', '--help'].include? params[0]
      end
    end
  end
end
