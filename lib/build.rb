module Circlarify
  class Build
    # @param [build_descriptor:Object] build_info
    def initialize(build_info)
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

    def outcome
      # Possible build outcomes:
      # :canceled, :infrastructure_fail, :timedout, :failed, :no_tests or :success
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

  end
end
