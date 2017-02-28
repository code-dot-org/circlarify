# circlarify
A set of CLI tools for analyzing Circle CI builds via their REST API.

## Setup
We manage dependencies with [Bundler](http://bundler.io/) so please install that first.

From the repository root, run `bundle install`.  Then you should be able to execute the tools directly.

The tools will write to `~/.circlarify` to cache build information and avoid redundant requests to the Circle CI API.  Cached build JSON gets compressed; caching summary data for 10,000 builds requires about 115MB of disk space.

## Tools

### compute-failure-rates
Compute daily build failure rates, optionally grouped by a branch or set of branches.

By default, computes a "Total" rate for all builds in range, a "Pipeline" rate for builds on the `production`, `test` and `staging` branches, and a "Branch" rate for all builds not included in the "Pipeline" rate.
```
╰○ ./compute-failure-rates --start 31800
Downloading 31800..32028 |Time: 00:00:01 | === | Time: 00:00:01
Failure rates for builds 31800..32028 by date (1.0 = 100% failures)
Date                  Total         Pipeline           Branch
2017-02-24    12/59 = 0.203     2/22 = 0.091    10/37 = 0.270
2017-02-26      0/3 = 0.000      0/2 = 0.000      0/1 = 0.000
2017-02-27   22/110 = 0.200     6/40 = 0.150    16/70 = 0.229
2017-02-28      3/6 = 0.500      0/3 = 0.000      3/3 = 1.000

```

You can also pull failure rates for a specific branch.  Here we ask for `staging` branch failure rate:
```
╰○ ./compute-failure-rates --start 31800 --group staging
Downloading 31800..32028 |Time: 00:00:01 | === | Time: 00:00:01
Failure rates for builds 31800..32028 by date (1.0 = 100% failures)
Date                  Total         Pipeline           Branch          staging
2017-02-24    12/59 = 0.203     2/22 = 0.091    10/37 = 0.270     2/19 = 0.105
2017-02-26      0/3 = 0.000      0/2 = 0.000      0/1 = 0.000      0/1 = 0.000
2017-02-27   22/110 = 0.200     6/40 = 0.150    16/70 = 0.229     6/36 = 0.167
2017-02-28      3/6 = 0.500      0/3 = 0.000      3/3 = 1.000      0/2 = 0.000

```

Usage:
```
Usage: ./compute-failure-rates [options]

  Examples:

    Default behavior, view stats for the last 30 builds:
    ./compute-failure-rates

    View stats for 30 builds ending at build 123:
    ./compute-failure-rates --end 123

    View stats for all builds since (and including) build 123:
    ./compute-failure-rates --start 123

    View status for builds in range 123-456 inclusive:
    ./compute-failure-rates --start 123 --end 456

  Options:
        --start StartBuildNumber     Start searching at build #. Default: Get 30 builds.
        --end EndBuildNumber         End searching at build #. Default: Latest build.
        --group branchName,branchName
                                     Add a column aggregating results for the listed branches.
        --csv                        Display results in CSV format.
    -h, --help                       Show this message

```

### test-flakiness
Computes failure rates for individual cucumber features.

When not grouped by build time, this tool will generate a list of features sorted by flakiness:

```
╰○ ./test-flakiness --start 31500 --branch staging
Computing flakiness rates on branch staging in builds 31500..32007 (1.0 = 100% failures)
Flake    n Test Name
0.495  216 ChromeLatestWin7_hourOfCodeFinish
0.312  160 ChromeLatestWin7_sharepage
0.262  149 ChromeLatestWin7_pixelation
0.174  132 ChromeLatestWin7_applab_embed
0.142  127 ChromeLatestWin7_legacyShareRemix
0.052  116 ChromeLatestWin7_stepMode
0.044  114 ChromeLatestWin7_applab_sharedApps
0.044  114 ChromeLatestWin7_projects
0.035  113 ChromeLatestWin7_callouts
0.035  114 ChromeLatestWin7_starwars
...
```

Where `Flake` is the failure rate and `n` is the sample size for the given range (total runs of that feature).

You can also group results by date to track flakiness changes over time, and filter results to feature names matching a given pattern.  Here we get flakiness by day for pixelation.feature:
```
╰○ ./test-flakiness --start 31500 --branch staging --group-by day --test pixelation
Computing flakiness rates for test pixelation on branch staging in builds 31500..32009 grouped by day (1.0 = 100% failures)
ChromeLatestWin7_pixelation
{Tue, 21 Feb 2017=>{:flakiness=>0.00, :sample_size=>3},
 Wed, 22 Feb 2017=>{:flakiness=>0.34, :sample_size=>38},
 Thu, 23 Feb 2017=>{:flakiness=>0.31, :sample_size=>45},
 Fri, 24 Feb 2017=>{:flakiness=>0.20, :sample_size=>25},
 Sat, 25 Feb 2017=>{:flakiness=>0.00, :sample_size=>1},
 Mon, 27 Feb 2017=>{:flakiness=>0.19, :sample_size=>32},
 Tue, 28 Feb 2017=>{:flakiness=>0.20, :sample_size=>5}}
```

Usage:
```                                                  
Usage: ./test-flakiness [options]
        --start StartBuildNumber     Start searching at build #
        --end EndBuildNumber         End searching at build #
        --branch BranchName          Limit results to builds for one branch
        --test "Test name filter"    Regular expression for filtering results to a certain test.
        --group-by Period            Select grouping period (day, week, month)
    -h, --help                       Show this message
```

### search-circle-builds
Helper for grepping through build logs.

Usage:
```
Usage: ./search-circle-builds [options]
        --start StartBuildNumber     Start searching at build #
        --end EndBuildNumber         End searching at build #
        --grep "String to Search for"
                                     Search for given string
        --whole-lines                Print entire lines of found strings in output
        --count                      Counts number of found strings in output
        --grep-container             Search given container # for grep string
        --grep-step                  Search given step (substring) for grep string
        --branch BranchName          Limit results to builds for one branch
    -h, --help                       Show this message
```
