# frozen_string_literal: true

require 'memoist'
require 'ostruct'
require_relative './build'
require_relative './circle_project'
require_relative './config'

module Circlarify
  #
  # Represents Circle CI builds on a particular repo.
  # Knows how to set up command line options and resolve them usefully into
  # a subset of builds we'll work with.
  #
  class Project
    extend Memoist

    def initialize
      @arguments = OpenStruct.new
    end

    def repository
      repo = @arguments.repository || Config.instance.repository
      unless repo
        raise ArgumentError,
              'No repository specified. Pass one (--repository) or configure '\
              "a default in #{USER_CONFIG_FILE_PATH}."
      end
      repo
    end

    def api
      CircleProject.new(repository)
    end

    # @return [Range] A range of build numbers matching the options passed
    def build_range
      if @arguments.after && @arguments.before && @arguments.count
        raise ArgumentError,
              'Cannot specify --after, --before AND --count: Maximum of two.'
      elsif @arguments.after && @arguments.before
        if @arguments.after > @arguments.before
          raise ArgumentError,
                "Invalid range #{@arguments.after}..#{@arguments.before}"
        end
        first = @arguments.after
        last = @arguments.before
      elsif @arguments.after && @arguments.count
        first = @arguments.after
        last = @arguments.after + @arguments.count - 1
      elsif @arguments.before && @arguments.count
        first = @arguments.before - @arguments.count + 1
        last = @arguments.before
      elsif @arguments.after
        first = @arguments.after
        last = api.latest_build_num
      elsif @arguments.before
        raise ArgumentError,
              'Cannot specify --before without --after or --count.'
      elsif @arguments.count
        last = api.latest_build_num
        first = last - @arguments.count + 1
      else
        # Default to 30 builds; the recent builds API call returns 30 builds.
        last = api.latest_build_num
        first = last - 29
      end
      @latest = last
      @earliest = first if @earliest.nil?
      first..last
    end

    # @param ensure_full_summary [Boolean] If true, will not use build metadata
    #   from the recent builds API, which omits certain fields (like 'steps')
    # @return [Array<build_descriptor:Object>] set of found build descriptors
    #   in given range.
    def builds(ensure_full_summary = false)
      ret = api.get_builds(build_range, ensure_full_summary)
         .map { |info| Build.new(api, info) }
      earliest = nil
      ret = ret.select do |build|
        next false if @arguments.after_date && build.queued_at && build.queued_at < @arguments.after_date
        next false if @arguments.before_date && build.queued_at && build.queued_at > @arguments.before_date
        earliest = build if build.queued_at && (earliest.nil? || build.build_num < earliest.build_num)
        true
      end
      @earliest = earliest.build_num
      ret
    end

    def restricted_build_range
      return 0..0 if @earliest.nil? || @latest.nil?
      @earliest..@latest
    end

    # Mix global configuration options into the option parser.
    # @param [OptionParser] opts
    def provide_cli_options(opts)
      opts.separator <<-BANNER

    BUILD SELECTION
      These options let you select which repository and which subset of builds
      you'd like to examine.
      Some options can be given configured defaults by setting them up in a
      local configuration file.  Yours should be found at:
      #{USER_CONFIG_FILE_PATH}

      BANNER

      opts.on('-r', '--repository RepositoryName', String,
              'Which repository to use (e.g. code-dot-org/code-dot-org)') do |s|
        @arguments.repository = s
      end

      opts.on('-a', '--after BuildNumber', Integer,
              'First build to include in build range.') do |n|
        @arguments.after = n
      end

      opts.on('-s', '--after-date date', String,
              'Only include builds after date. Must still be within the range' +
              'specififed by --before and --after.') do |d|
        @arguments.after_date = DateTime.parse(d)
      end

      opts.on('-b', '--before BuildNumber', Integer,
              'Last build to include in build range.') do |n|
        @arguments.before = n
      end

      opts.on('-e', '--before-date date', String,
              'Only include builds before date. Must still be within the range' +
              'specififed by --before and --after.') do |d|
        @arguments.before_date = DateTime.parse(d)
      end

      opts.on('-c', '--count BuildCount', Integer,
              'How many builds to include in build range.') do |n|
        @arguments.count = n
      end

      opts.on('--end BuildNumber', Integer,
              '(deprecated) see --before') do |n|
        @arguments.before = n
      end

      opts.on('--start BuildNumber', Integer,
              '(deprecated) see --after') do |n|
        @arguments.after = n
      end

      opts.on_tail('-h', '--help',
                   'Show this message.') do
        puts opts
        exit
      end
    end

    memoize :api
    memoize :build_range
    memoize :builds
  end
end
