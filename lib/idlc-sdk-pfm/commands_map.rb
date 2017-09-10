module Pfm
  class CommandsMap
    NULL_ARG = Object.new

    CommandSpec = Struct.new(:name, :constant_name, :require_path, :description)

    class CommandSpec

      def instantiate
        require require_path
        command_class = Pfm::Command.const_get(constant_name)
        command_class.new
      end

    end

    attr_reader :command_specs

    def initialize
      @command_specs = {}
    end

    def builtin(name, constant_name, require_path: NULL_ARG, desc: "")
      if null?(require_path)
        snake_case_path = name.tr("-", "_")
        require_path = "idlc-sdk-pfm/command/#{snake_case_path}"
      end
      command_specs[name] = CommandSpec.new(name, constant_name, require_path, desc)
    end

    def instantiate(name)
      spec_for(name).instantiate
    end

    def have_command?(name)
      command_specs.key?(name)
    end

    def command_names
      command_specs.keys
    end

    def spec_for(name)
      command_specs[name]
    end

    private

    def null?(argument)
      argument.equal?(NULL_ARG)
    end
  end

  def self.commands_map
    @commands_map ||= CommandsMap.new
  end

  def self.commands
    yield commands_map
  end
end
