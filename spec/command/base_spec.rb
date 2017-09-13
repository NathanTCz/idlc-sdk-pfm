require 'spec_helper'

require 'idlc-sdk-pfm/command/plan'
require 'idlc-sdk-pfm/command/build'

describe Pfm::Command::Base do
  class TestCommand < Pfm::Command::Base
    banner 'use me please'

    option :argue,
           short:       '-a ARG',
           long:        '--arg ARG',
           description: 'An option with a required argument'

    option :user,
           short: '-u',
           long: '--user',
           description: 'If the user exists',
           boolean: true

    def run(params)
      parse_options(params)
      msg("thanks for passing me #{config[:user]}")
    end
  end

  let(:stderr_io) { StringIO.new }
  let(:stdout_io) { StringIO.new }
  let(:command_instance) { TestCommand.new }

  def stdout
    stdout_io.string
  end

  def stderr
    stderr_io.string
  end

  before do
    allow(command_instance).to receive(:stdout).and_return(stdout_io)
    allow(command_instance).to receive(:stderr).and_return(stderr_io)
  end

  def run_command(options)
    command_instance.run_with_default_options(options)
  end

  it 'should print the banner for -h' do
    run_command(['-h'])
    expect(stdout).to include("use me please\n")
  end

  it 'should print the banner for --help' do
    run_command(['--help'])
    expect(stdout).to include("use me please\n")
  end

  it 'prints the options along with the banner when displaying the help message' do
    run_command(['--help'])
    expect(stdout).to include('-u, --user                       If the user exists')
  end

  it 'should print the version for -v' do
    run_command(['-v'])
    expect(stdout).to eq("Pfm Version: #{Pfm::VERSION}\n")
  end

  it 'should print the version for --version' do
    run_command(['--version'])
    expect(stdout).to eq("Pfm Version: #{Pfm::VERSION}\n")
  end

  it 'should run the command passing in the custom options for long custom options' do
    run_command(['--user'])
    expect(stdout).to eq("thanks for passing me true\n")
  end

  it 'should run the command passing in the custom options for short custom options' do
    run_command(['-u'])
    expect(stdout).to eq("thanks for passing me true\n")
  end

  describe 'when given invalid options' do
    it 'prints the help banner and exits gracefully' do
      expect(run_command(%w[-foo])).to eq(1)

      expect(stderr).to eq("ERROR: invalid option: -foo\n\n")

      expected = <<-E
use me please
    -a, --arg ARG                    An option with a required argument
    -h, --help                       Show this message
    -u, --user                       If the user exists
    -V, --verbose                    Show detailed output
    -v, --version                    Show pfm version

E
      expect(stdout).to eq(expected)
    end
  end

  describe 'when given an option that requires an argument with no argument' do
    it 'prints the help banner and exits gracefully' do
      expect(run_command(%w[-a])).to eq(1)

      expect(stderr).to eq("ERROR: missing argument: -a\n\n")

      expected = <<-E
use me please
    -a, --arg ARG                    An option with a required argument
    -h, --help                       Show this message
    -u, --user                       If the user exists
    -V, --verbose                    Show detailed output
    -v, --version                    Show pfm version

E
      expect(stdout).to eq(expected)
    end
  end

  describe 'when locating infrastructure directory' do
    let(:deploy_command) { Pfm::Command::Plan.new }

    it 'should raise InvalidRepository if directory is not looking like an infrastructure repository' do
      expect { deploy_command.run(['-h']) }.to raise_error Pfm::Command::Base::InvalidRepository
    end
  end
end
