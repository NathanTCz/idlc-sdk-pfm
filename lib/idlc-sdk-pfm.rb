require 'mixlib/cli'
require 'mixlib/shellout'
require 'packer/binary'
require 'terraform/binary'

require 'idlc-sdk-core'
require 'idlc-sdk-build'
require 'idlc-sdk-deploy'

require 'idlc-sdk-pfm/version'
require 'idlc-sdk-pfm/settings'
require 'idlc-sdk-pfm/helpers'
require 'idlc-sdk-pfm/cli'
require 'idlc-sdk-pfm/commands_map'
require 'idlc-sdk-pfm/builtin_commands'

# Default region
ENV['AWS_REGION'] = 'us-east-1' unless ENV['AWS_REGION']

# Load config file as mapp of strings ex. SETTINGS[ 'AWS_REGION' ] = 'us-east-1'
SETTINGS = Pfm::Settings.new(true).settings_strings

# Global repository version file
REPO_VERSION_FILE = 'version'.freeze

# Load the current repository version number
REPO_VERSION = Idlc::Utility.set_global_version(REPO_VERSION_FILE)
