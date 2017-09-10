module Pfm
  module Command
    module ValidatorCommands
      class Infrastructure < Base
        banner 'Usage: pfm validate infrastructure [options]'

        option :app_release,
               short:        '-a VERSION',
               long:         '--app-release VERSION',
               description:  'Application Version Number to Deploy',
               default:      ''

        options.merge!(SharedValidatorOptions.options)

        def run
          @config[:validator_name] = 'infrastructure'

          read_and_validate_params
          setup_artifacts_dirs

          if params_valid?
            deploy_setup
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
          Terraform::Binary.validate(@workspace.tmp_dir.to_s)
          msg('Verified repository..')
        rescue Terraform::Binary::Command::CommandFailure
          raise ValidationError, 'Failures reported during validation!'
        end
      end
    end
  end
end
