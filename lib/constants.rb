module Circlarify
  LOCAL_FILES_PATH = File.expand_path('~/.circlarify').freeze
  USER_CONFIG_FILE_NAME = 'config.yml'
  USER_CONFIG_FILE_PATH = "#{LOCAL_FILES_PATH}/#{USER_CONFIG_FILE_NAME}".freeze
  CACHE_DIRECTORY = "#{LOCAL_FILES_PATH}/builds".freeze
end
