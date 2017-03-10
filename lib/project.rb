require 'ostruct'
require_relative './circle_project'
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

    # @return [Range] A range of build numbers matching the options passed
    def build_range
      if @arguments.after && @arguments.before && @arguments.count
        raise ArgumentError.new("Cannot specify --after, --before AND --count: Maximum of two.")
      elsif @arguments.after && @arguments.before
        if @arguments.after > @arguments.before
          raise ArgumentError.new("Invalid range #{@arguments.after}..#{@arguments.before}")
        end
        (@arguments.after)..(@arguments.before)
      elsif @arguments.after && @arguments.count
        (@arguments.after)..(@arguments.after + @arguments.count - 1)
      elsif @arguments.before && @arguments.count
        (@arguments.before - @arguments.count + 1)..(@arguments.before)
      elsif @arguments.after
        (@arguments.after)..(latest_build_num)
      elsif @arguments.before
        raise ArgumentError.new("Cannot specify --before without --after or --count.")
      elsif @arguments.count
        last = latest_build_num
        (last - @arguments.count + 1)..(last)
      else
        # Default to 30 builds since the recent builds API call returns 30 builds.
        last = latest_build_num
        (last - 29)..(last)
      end
    end

    def latest_build_num
      CircleProject.new(repository).get_latest_build_num
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
        @arguments.repository = s
      end

      opts.on('-a', '--after BuildNumber', Integer, 'First build to include in build range.') do |n|
        @arguments.after = n
      end

      opts.on('-b', '--before BuildNumber', Integer, 'Last build to include in build range.') do |n|
        @arguments.before = n
      end

      opts.on('-c', '--count BuildCount', Integer, 'How many builds to include in build range.') do |n|
        @arguments.count = n
      end

      opts.on('--start BuildNumber', Integer, '(deprecated) see --after') do |n|
        @arguments.after = n
      end
      opts.on('--end EndBuildNumber', Integer, '(deprecated) see --before') do |n|
        @arguments.before = n
      end

      opts.on_tail('-h', '--help', 'Show this message.') do
        puts opts
        exit
      end
    end
  end
end
