require 'ostruct'
require 'yaml'

#
# Reads configuration defaults out of ~/.circlarify/config
# Allows those defaults to be overriden by command-line options
# Exposes those settings to the rest of the application
#
class Config
  USER_CONFIG_FILE_NAME = 'config.yml'
  USER_CONFIG_FILE_PATH = File.expand_path("~/.circlarify/#{USER_CONFIG_FILE_NAME}").freeze

  def initialize
    @arguments = OpenStruct.new
  end

  def repository
    @arguments.repository || user_config.repository || raise(ArgumentError.new <<-ERR)
No repository specified.  Pass --repository <repository name> or configure one in #{USER_CONFIG_FILE_PATH}.
    ERR
  end

  # Mix global configuration options into the option parser, with documentation.
  # @param [OptionParser] opts
  def add_to_cli_options(opts)
    opts.separator <<-BANNER

  GLOBAL CONFIGURATION OPTIONS:
    These options can all be passed on the command line, or they can be given
    configured defaults by editing your local config file.
    Your config file should be at #{USER_CONFIG_FILE_PATH}.

    BANNER

    opts.on('-r', '--repository RepositoryName', String, 'Which repository to use (e.g. code-dot-org/code-dot-org)') do |s|
      @arguments.repository = s
    end
  end

  def user_config
    @user_config ||= OpenStruct.new YAML.load_file(USER_CONFIG_FILE_PATH)
  rescue Exception
    # Problem loading the user config? Just act like there isn't one there.
    @user_config = OpenStruct.new
  end
end
