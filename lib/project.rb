require 'ostruct'
require_relative './config'

module Circlarify

  #
  # Represents Circle CI builds on a particular repo.
  # Knows how to set up command line options and resolve them usefully into
  # a subset of builds we'll work with.
  #
  class Project
    def initialize
      @arguments = OpenStruct.new
    end

    def repository
      @arguments.repository ||
          Config.instance.repository ||
          raise(ArgumentError.new("No repository specified.  Pass one (--repository) or configure a default in #{Config.USER_CONFIG_FILE_PATH}."))
    end

    # Mix global configuration options into the option parser, with documentation.
    # @param [OptionParser] opts
    def provide_cli_options(opts)
      opts.separator <<-BANNER
    BUILD SELECTION
      These options let you select which repository and which subset of builds
      you'd like to examine.
      Some options can be given configured defaults by setting them up in a
      local configuration file.  Yours should be found at:
      #{Config::USER_CONFIG_FILE_PATH}

      BANNER

      opts.on('-r', '--repository RepositoryName', String, 'Which repository to use (e.g. code-dot-org/code-dot-org)') do |s|
        @repository = s
      end

      opts.on_tail('-h', '--help', 'Show this message.') do
        puts opts
        exit
      end
    end
  end
end
