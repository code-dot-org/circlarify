require 'ostruct'
require 'singleton'
require 'yaml'
require_relative './constants'

#
# Reads configuration defaults out of ~/.circlarify/config
# Allows those defaults to be overriden by command-line options
# Exposes those settings to the rest of the application
#
module Circlarify
  class Config
    include Singleton
    USER_CONFIG_FILE_NAME = 'config.yml'
    USER_CONFIG_FILE_PATH = "#{Circlarify::LOCAL_FILES_PATH}/#{USER_CONFIG_FILE_NAME}".freeze

    def initialize
      @user_config = OpenStruct.new YAML.load_file(USER_CONFIG_FILE_PATH)
    rescue Exception
      # Problem loading the user config? Just act like there isn't one there.
      @user_config = OpenStruct.new
    end

    def repository
      @user_config.repository
    end
  end
end
