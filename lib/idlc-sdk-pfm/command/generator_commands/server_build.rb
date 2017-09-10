module Pfm
  module Command
    module GeneratorCommands
      class ServerBuild < Base
        banner 'Usage: pfm generate server-build NAME [options]'

        options.merge!(SharedGeneratorOptions.options)

        def run
          read_and_validate_params
          if params_valid?
            setup_context

            mk_build_dirs
            default_build_files
            default_cookbooks
          else
            errors.each { |error| err("Error: #{error}") }
            parse_options(params)
            msg(opt_parser)
            1
          end
        end

        def mk_build_dirs
          %w(
            chef/bake/cookbooks
            chef/fry/cookbooks
            chef/vendor/cookbooks
          ).each do |path|
            FileUtils.mkdir_p("#{base_dir}/#{path}", verbose: verbose?(params))
          end
        end

        def default_build_files
          %w(
            metadata
          ).each do |file|
            FileUtils.touch("#{base_dir}/#{file}", verbose: verbose?(params))
          end
        end

        def default_cookbooks
          %w(
            chef/bake/cookbooks/bake
            chef/fry/cookbooks/fry
          ).each do |cookbook|
            system("chef generate cookbook #{base_dir}/#{cookbook} -g #{__dir__}/skeletons/code_generator")
          end
        end

        def base_dir
          "builds/#{@params.first}"
        end
      end
    end
  end
end
