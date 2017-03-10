# frozen_string_literal: true

module Circlarify
  # Represents a single Circle build
  class Build
    # @param [CircleProject] api
    # @param [build_descriptor:Object] build_info
    def initialize(api, build_info)
      @api = api
      @info = build_info
    end

    def build_num
      @info['build_num']
    end

    def build_time_millis
      @info['build_time_millis']
    end

    def branch
      @info['branch']
    end

    def branch?(branch_name)
      branch_name.nil? || (@info['branch'] == branch_name)
    end

    # @param [Fixnum] container The container ID #
    # @param [String] step The build step to search for (e.g. "rake install")
    # @return [Object, nil] full build output JSON object from CircleCI,
    #   or nil if error in retrieval
    # Example output JSON: https://gist.github.com/bcjordan/8349fbb1edc284839b42ae53ad19b68a
    def get_log(container, step)
      @api.get_log(build_num, container, step)
    end

    def outcome
      # Possible build outcomes:
      # :canceled, :infrastructure_fail, :timedout, :failed, :no_tests, :success
      @info['outcome']
    end

    def succeeded?
      @info['outcome'] == 'success'
    end

    def failed?
      @info['outcome'] == 'failed' || @info['outcome'] == 'timedout'
    end

    def queued_at
      DateTime.parse(@info['queued_at'])
    rescue => _
      nil
    end

    def start_time
      Time.parse(@info['start_time'])
    rescue => _
      nil
    end

    def steps
      @info['steps']
    end

    def url
      @api.build_url build_num
    end
  end
end
