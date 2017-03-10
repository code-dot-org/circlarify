# frozen_string_literal: true

module Circlarify
  LOCAL_FILES_PATH = File.expand_path('~/.circlarify')
  USER_CONFIG_FILE_NAME = 'config.yml'
  USER_CONFIG_FILE_PATH = "#{LOCAL_FILES_PATH}/#{USER_CONFIG_FILE_NAME}"
  CACHE_DIRECTORY = "#{LOCAL_FILES_PATH}/builds"
end
