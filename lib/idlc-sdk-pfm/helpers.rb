module Pfm
  # Module of common functions that are used frequently in every namespace
  module Helpers
    module_function

    # Runs given commands using mixlib-shellout
    #
    # @param command_args [String] the system command to run
    def system_command(*command_args)
      cmd = Mixlib::ShellOut.new(*command_args)
      cmd.run_command
      err(cmd.stderr)
      msg(cmd.stdout)
      cmd
    end

    # Print the given string to stderr
    #
    # @param message [String] the string to print
    def err(message)
      stderr.print("#{message}\n")
    end

    # Print the given string to stdout
    #
    # @param message [String] the string to print
    def msg(message)
      stdout.print("#{message}\n")
    end

    # Only prints the given string to stdout when the environment variable
    # DEBUG = true
    #
    # @param message [String] the string to print
    def debug(message)
      stdout.print("#{message}\n") if ENV['DEBUG']
    end

    private

    def stdout
      $stdout
    end

    def stderr
      $stderr
    end
  end
end
