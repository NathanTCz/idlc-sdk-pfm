module Pfm
  class CLI
    include Mixlib::CLI
    include Pfm::Helpers

    banner(<<-BANNER)
Usage:
    pfm -h/--help
    pfm -v/--version
    pfm command [arguments...] [options...]
BANNER

    option :version,
           short: '-v',
           long: '--version',
           description: 'Show pfm version',
           boolean: true

    option :help,
           short: '-h',
           long: '--help',
           description: 'Show this message',
           boolean: true

    option :verbose,
           short:        '-V',
           long:         '--verbose',
           description:  'Show detailed output',
           boolean:      true,
           default:      false

    attr_reader :argv

    def initialize(argv)
      @argv = argv
      super() # mixlib-cli #initialize doesn't allow arguments
    end

    def run
      subcommand_name, *subcommand_params = argv

      ENV['DEBUG'] = true if verbose?

      #
      # Runs the appropriate subcommand if the given parameters contain any
      # subcommands.
      #
      if subcommand_name.nil? || option?(subcommand_name)
        handle_options
      elsif have_command?(subcommand_name)
        subcommand = instantiate_subcommand(subcommand_name)
        exit_code = subcommand.run_with_default_options(subcommand_params)
        exit normalized_exit_code(exit_code)
      else
        err "Unknown command `#{subcommand_name}'."
        show_help
        exit 1
      end
    rescue OptionParser::InvalidOption => e
      err(e.message)
      show_help
      exit 1
    end

    # If no subcommand is given, then this class is handling the CLI request.
    def handle_options
      parse_options(argv)
      if config[:version]
        show_version
      else
        show_help
      end
      exit 0
    end

    def show_version
      msg("Pfm Version: #{Pfm::VERSION}")
    end

    def show_help
      msg(banner)
      msg("\nAvailable Commands:")

      justify_length = subcommands.map(&:length).max + 2
      subcommand_specs.each do |name, spec|
        msg("    #{name.ljust(justify_length)}#{spec.description}")
      end
    end

    def exit(n)
      Kernel.exit(n)
    end

    def commands_map
      Pfm.commands_map
    end

    def have_command?(name)
      commands_map.have_command?(name)
    end

    def subcommands
      commands_map.command_names
    end

    def subcommand_specs
      commands_map.command_specs
    end

    def option?(param)
      param =~ /^-/
    end

    def verbose?
      @config[:verbose]
    end

    def instantiate_subcommand(name)
      commands_map.instantiate(name)
    end

    private

    def normalized_exit_code(maybe_integer)
      if maybe_integer.is_a?(Integer) && (0..255).cover?(maybe_integer)
        maybe_integer
      else
        0
      end
    end

    # Find PATH or Path correctly if we are on Windows
    def path_key
      env.keys.grep(/\Apath\Z/i).first
    end

    # upcase drive letters for comparison since ruby has a String#capitalize function
    def drive_upcase(path)
      if Chef::Platform.windows? && path[0] =~ /^[A-Za-z]$/ && path[1, 2] == ':\\'
        path.capitalize
      else
        path
      end
    end

    def env
      ENV
    end
  end
end
