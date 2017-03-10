# frozen_string_literal: true

require 'ostruct'
require 'singleton'
require 'yaml'
require_relative './constants'

module Circlarify
  #
  # Reads configuration defaults out of ~/.circlarify/config
  # Allows those defaults to be overriden by command-line options
  # Exposes those settings to the rest of the application
  #
  class Config
    include Singleton

    def initialize
      @user_config = OpenStruct.new YAML.load_file(USER_CONFIG_FILE_PATH)
    rescue
      # Problem loading the user config? Just act like there isn't one there.
      @user_config = OpenStruct.new
    end

    def repository
      @user_config.repository
    end
  end
end
