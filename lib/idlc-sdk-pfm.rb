require 'mixlib/cli'
require 'mixlib/shellout'
require 'packer/binary'
require 'terraform/binary'

require 'idlc-sdk-build'
require 'idlc-sdk-deploy'

require 'idlc-sdk-pfm/version'
require 'idlc-sdk-pfm/settings'
require 'idlc-sdk-pfm/helpers'
require 'idlc-sdk-pfm/cli'
require 'idlc-sdk-pfm/commands_map'
require 'idlc-sdk-pfm/builtin_commands'

# Load config file as mapp of strings ex. SETTINGS[ 'AWS_REGION' ] = 'us-east-1'
SETTINGS = Pfm::Settings.new(true).settings_strings
