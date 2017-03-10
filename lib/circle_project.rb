# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'memoist'
require 'open-uri'
require 'parallel'
require 'zlib'
require_relative './constants'

GITHUB_PROJECT_WEB_BASE = 'https://circleci.com/gh'
GITHUB_PROJECT_API_BASE = 'https://circleci.com/api/v1.1/project/github'

# Abstracted access to a Circle CI project builds via their REST API
class CircleProject
  extend Memoist

  # @param [String] repository - repo name, like "code-dot-org/code-dot-org"
  def initialize(repository)
    @project_web_base = "#{GITHUB_PROJECT_WEB_BASE}/#{repository}"
    @project_api_base = "#{GITHUB_PROJECT_API_BASE}/#{repository}"
  end

  def build_url(build_num)
    "#{@project_web_base}/#{build_num}"
  end

  # @param build_num [Fixnum] The CircleCI build #
  # @param ensure_full_summary [Boolean] If true, will not use build metadata
  #        from the recent builds API, which omits certain fields (like 'steps')
  # @return [Object] build descriptor object from the CircleCI API
  #   Example output JSON: https://gist.github.com/bcjordan/02f7c2906b524fa86ec75b19f9a72cd2
  def get_build(build_num, ensure_full_summary = false)
    # First, check local cache
    return cached_build(build_num) if cached?(build_num)

    # Second, try pulling from the build summary
    unless ensure_full_summary
      short_summary = recent_builds.find { |b| b['build_num'] == build_num }
      return short_summary if short_summary
    end

    # Finally, download the whole thing
    fetch_build build_num
  end

  def fetch_build(build_num)
    # Download the build, parse it, and save it to the local cache if the
    # build outcome is determined
    body = download_build_body build_num
    build_summary = JSON.parse(body)
    if build_summary && !build_summary['outcome'].nil?
      save_build_to_cache build_num, body
    end
    build_summary
  end

  def download_build_body(build_num)
    download_attempts_remaining = 3
    while download_attempts_remaining.positive?
      begin
        return open("#{@project_api_base}/#{build_num}").read
      rescue
        download_attempts_remaining -= 1
        sleep(0.25)
      end
    end
  end

  def cached?(build_num)
    File.exist? cache_file_name(build_num)
  end

  def save_build_to_cache(build_num, body)
    FileUtils.mkdir_p(Circlarify::CACHE_DIRECTORY)
    Zlib::GzipWriter.open(cache_file_name(build_num)) do |file|
      file.write body
    end
  end

  def cached_build(build_num)
    Zlib::GzipReader.open(cache_file_name(build_num)) do |file|
      return JSON.parse(file.read)
    end
  end

  # @param [Fixnum] build_num The build ID #
  # @param [Fixnum] container_num The container ID #
  # @param [String] grep_for_step The build step to search for
  #   (e.g. "rake install")
  # @param [Bool] verbose Whether to report errors
  # @return [Object, nil] full build output JSON object from CircleCI,
  #   or nil if error in retrieval
  # Example output JSON: https://gist.github.com/bcjordan/8349fbb1edc284839b42ae53ad19b68a
  def get_log(build_num, container_num, grep_for_step, verbose = false)
    JSON.parse(
      open(
        build_step_output_url(
          get_build(build_num, true),
          container_num, grep_for_step
        )
      ).read
    )
  rescue => e
    STDERR.puts e.message if verbose
  end

  # @return [Array<build_descriptor:Object>] 30 most recent build descriptors
  # from the CircleCI API, in reverse-chronological order.
  def recent_builds
    JSON.parse(open(@project_api_base).read)
  end

  # @return [Integer] The most recent build number in the project
  def latest_build_num
    recent_builds.first['build_num']
  end

  # Retrieve the set of build descriptor objects from the CircleCI API for this
  # project for the given range
  # @param range [Enumerable<Fixnum>] set of build numbers to retrieve
  # @param ensure_full_summary [Boolean] If true, will not use build metadata
  #        from the recent builds API, which omits certain fields (like 'steps')
  # @return [Array<build_descriptor:Object>] set of found build descriptors
  def get_builds(range, ensure_full_summary = false)
    raise ArgumentError unless range.is_a?(Enumerable)

    # Download the build information we need in parallel
    Parallel.map(
      range,
      progress: "Downloading #{range.min}..#{range.max}",
      in_processes: 50
    ) { |n| get_build(n, ensure_full_summary) }
  end

  memoize :get_build
  memoize :get_log
  memoize :recent_builds

  private

  # Returns the full output URL for a given build step
  # @param [Fixnum] build_object The build information object from the
  #   Circle API
  # @param [Fixnum] container_id The container ID #
  # @param [String] grep_for_step The build step to search for
  #   (e.g. "rake install")
  def build_step_output_url(build_object, container_id, grep_for_step)
    build_object['steps'].select do |o|
      o['name'].include? grep_for_step
    end[0]['actions'][container_id]['output_url']
  end

  # @return [String] Location of cache file for build
  def cache_file_name(build_num)
    "#{Circlarify::CACHE_DIRECTORY}/#{build_num}.json.gz"
  end
end
