module Pfm
  module Command
    module ValidatorCommands
      class ServerBuild < Base
        banner 'Usage: pfm validate server-build BUILD_NAME [options]'

        option :build_version,
               short:        '-b VERSION',
               long:         '--build-version VERSION',
               description:  'override version number of build',
               default:      nil

        option :build_template,
               short:        '-t TEMPLATE',
               long:         '--build-template TEMPLATE',
               description:  'The Build Template to use. Defaults to build.json',
               default:      'build.json'

        option :build_metadata,
               short:        '-m METADATA_FILE',
               long:         '--build-metadata METADATA_FILE',
               description:  'The build metadata file to use. Defaults to \'metadata\'',
               default:      'metadata'

        options.merge!(SharedValidatorOptions.options)

        def run
          read_and_validate_params
          setup_artifacts_dirs

          if params_valid?
            build_setup
            validate
            # @workspace.cleanup causing bundler issues
            0
          else
            errors.each { |error| err("Error: #{error}") }
            parse_options(params)
            msg(opt_parser)
            1
          end
        rescue ValidationError => e
          err("ERROR: #{e}")
          1
        end

        def validate
          lint_packer
          lint_chef
          unit_test

          raise ValidationError, 'Failures reported during validation!' if @failure
          msg('Verified repository..')
        end

        def lint_packer
          Packer::Binary.validate("#{@build_config.dump_build_vars} #{@config[:build_template]}")
        rescue Packer::Binary::Command::CommandFailure
          @failure = true
        end

        def lint_chef
          base_path = 'chef'
          cookbooks_dir = 'cookbooks'

          # Loop through the base directory looking through all of the cookbooks
          # for unit tests
          Dir.entries(base_path).each do |dir|
            next unless File.directory? "#{base_path}/#{dir}/#{cookbooks_dir}"
            next if dir.to_s == 'vendor'

            Dir.entries("#{base_path}/#{dir}/#{cookbooks_dir}").each do |cookbook|
              next unless File.directory? "#{base_path}/#{dir}/#{cookbooks_dir}/#{cookbook}"
              # skip directories eg. '.' and '..'
              next if cookbook.to_s == '.' || cookbook.to_s == '..'

              # Run the syntax and semantics checkers
              msg("\nRunning Rubocop on #{cookbook} cookbook")

              # Copy in global .foodcritic file if set
              debug("copying #{SETTINGS['RUBOCOP_RULES_FILE']} to #{Dir.pwd}")
              system("cp #{SETTINGS['RUBOCOP_RULES_FILE']} #{Dir.pwd}") if File.exist? SETTINGS['RUBOCOP_RULES_FILE']

              gem_path = `bundle show rubocop-junit-formatter`.strip!
              system("rubocop \\
                --format html -o #{@artifacts_dir}/rubocop/#{cookbook}_rubocop_output.html \\
                -r #{gem_path}/lib/rubocop/formatter/junit_formatter.rb \\
                --format RuboCop::Formatter::JUnitFormatter -o #{@reports_dir}/rubocop/#{cookbook}_junit.xml \\
                #{base_path}/#{dir}/#{cookbooks_dir}/#{cookbook}") || @failure = true

              msg("Running Foodcritic on #{cookbook} cookbook")
              ENV['FOODCRITIC_JUNIT_OUTPUT_DIR'] = "#{@reports_dir}/foodcritic"
              ENV['FOODCRITIC_JUNIT_OUTPUT_FILE'] = "#{cookbook}_foodcritic_junit.xml"

              # Copy in global .foodcritic file if set
              debug("copying #{SETTINGS['FOODCRITIC_RULES_FILE']} to #{Dir.pwd}")
              system("cp #{SETTINGS['FOODCRITIC_RULES_FILE']} #{base_path}/#{dir}/#{cookbooks_dir}/#{cookbook}") if File.exist? SETTINGS['FOODCRITIC_RULES_FILE']

              # Capure output but also fail if applicable
              system("foodcritic #{base_path}/#{dir}/#{cookbooks_dir}/#{cookbook} -C > #{cookbook}_foodcritic.out") || @failure = true
              system("foodcritic-junit < #{cookbook}_foodcritic.out")
            end
          end
        end

        def unit_test
          # load chefspec here as it load chef and can take a long time on some systems
          # so we only want to load it when we absolutely need it
          require 'chefspec'
          base_path = 'chef'
          cookbooks_dir = 'cookbooks'

          # Loop through the base directory looking through all of the cookbooks
          # for unit tests
          Dir.entries(base_path).each do |dir|
            next unless File.directory? "#{base_path}/#{dir}/#{cookbooks_dir}"
            next if dir.to_s == 'vendor'

            Dir.entries("#{base_path}/#{dir}/#{cookbooks_dir}").each do |cookbook|
              next unless File.directory? "#{base_path}/#{dir}/#{cookbooks_dir}/#{cookbook}"
              # skip directories eg. '.' and '..'
              next if cookbook.to_s == '.' || cookbook.to_s == '..'

              # run rspec unit tests
              Dir.chdir("#{base_path}/#{dir}/#{cookbooks_dir}/#{cookbook}") do
                msg("\nRunning unit tests for #{cookbook} cookbook")
                system("rspec -r rspec_junit_formatter --format progress --format RspecJunitFormatter -o #{@reports_dir}/rspec/#{cookbook}_junit.xml") || @failure = true
              end
            end
          end
        end
      end
    end
  end
end
