require 'guard/compat/plugin'

require 'childprocess'

module Guard
  class Maven < Plugin

    # Initializes a Guard plugin.
    # Don't do any work here, especially as Guard plugins get initialized even if they are not in an active group!
    #
    # @param [Array<Guard::Watcher>] watchers the Guard plugin file watchers
    # @param [Hash] options the custom Guard plugin options
    # @option options [Symbol] group the group this Guard plugin belongs to
    # @option options [Boolean] any_return allow any object to be returned from a watcher
    #
    def initialize(options = {})
      super
      @options = options
    end

    # Called once when Guard starts. Please override initialize method to init stuff.
    #
    # @raise [:task_has_failed] when start has failed
    # @return [Object] the task result
    #
    def start
      start_cli
      run_all if @options[:all_on_start]
    end

    def start_cli
      Compat::UI.info "Starting MVN cli..."

      r, w = IO.pipe
      @cli = ChildProcess.build("mvn", "org.twdata.maven:maven-cli-plugin:1.0.11:execute-phase")
      @cli.io.stdout = @cli.io.stderr = w
      @cli.duplex = true
      @cli.start
      # w.close

      @cliOut = r
      @cliIn = @cli.io.stdin

      # Wait until cli has started and opened socket access.
      while true
        line = @cliOut.readline
        puts line
        break if line.match(/Waiting for commands/)
      end
      Compat::UI.info "Maven CLI has started"
    end

    # Called when just `enter` is pressed
    # This method should be principally used for long action like running all specs/tests/...
    #
    # @raise [:task_has_failed] when run_all has failed
    # @return [Object] the task result
    #
    def run_all
      run_maven_tests
    end

    # Default behaviour on file(s) changes that the Guard plugin watches.
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_change has failed
    # @return [Object] the task result
    #
    def run_on_modifications(paths)
      # for now run all
      if paths.include? 'all'
        run_all
      else
        run_maven_tests :classes => paths
      end
    end

    private

    def notify(success, name, data={})
      title = 'Maven Tests'
      message = "Maven Test Results:"
      if data[:test_counts].empty?
        message += "No Tests Run"
      else
        message = guard_message(data[:test_counts][:total], data[:test_counts][:fail],data[:test_counts][:error],data[:test_counts][:skip],data[:total_time])
      end
      image = success ? :success : :failed
      Notifier.notify(message, title: title, image: image)
    end

    # Parses the results of the test run and
    # returns useful information for reporting:
    #  - number of tests
    #  - number of failed tests
    #  - number of errors
    #  - number of skipped tests
    #  - total time
    #
    # @param  results [String] The output of the test run
    #
    # @return [Hash] the relevant information
    def parse_test_results(results)
      data = { :success => true, :test_counts => [], :failures => [] }

      time = results.match(/\[INFO\] Total time: ([sm\d\.]+)/i)
      data[:total_time] = time[1] if time

      counts = results.match(/Tests run: (\d+), Failures: (\d+), Errors: (\d+), Skipped: (\d+)\n/)
      if counts
        data[:results] = counts[0]
        data[:test_counts] = {
          :total => counts[1].to_i,
          :fail => counts[2].to_i,
          :error => counts[3].to_i,
          :skip => counts[4].to_i,
          :pass => counts.to_a[1..-1].inject{|sum,x| sum.to_i - x.to_i }
        }

        data[:success] = false if counts[3].to_i + counts[2].to_i > 0
      end

      failures = results.match /Failed tests:(.*)\n\nTests run/im
      data[:failures] = failures ? failures[1].split("\n").compact : []

      if results =~ /COMPILATION ERROR/
        data[:success] = false
        data[:dump] = true
      end

      data
    end

    def run_maven_tests(options={})
      # cmds = ['mvn'] + (@options[:goals] || ['clean', 'test'])
      cmds = @options[:goals] || ['clean', 'test', '-DfailIfNoTests=false']

      if options[:classes]
        cmds << "-Dtest=#{options[:classes].join(',')}"
        options[:name] ||= options[:classes].join("\n")
      end

      Compat::UI.info "Running #{cmds.join ' '}" if @options[:verbose]

      output = []
      welcome = @cliOut.read(7).strip
      raise "Unexpected output '#{welcome}' when talking to cli" unless welcome == "maven>"

      @cliIn.puts cmds.join(' ')

      while true
        # Peek at the first 7 chars of next line. If it's maven> then the command finished and is waiting for more input.
        peek = @cliOut.read(7)

        if peek == "maven> "
          break
        end

        line = peek + @cliOut.readline

        Compat::UI.info line.chomp if @options[:verbose]
        clean_output(line.chomp) unless @options[:verbose]
        output << line.chomp
      end

      # Put an empty line to CLI, so that it outputs another prompt that we don't consume until next run.
      @cliIn.puts("")

      results = output.join("\n")

      data = parse_test_results(results)
      success = false unless data[:success]

      unless @options[:verbose]
        Compat::UI.info "Failed Tests:\n#{data[:failures].join("\n")}" unless data[:failures].empty?
        Compat::UI.info results if data[:dump]
      end

      notify(success, options[:name] || '', data)
    end

    def clean_output(line)
      if line =~ /^Running/
        puts line
      elsif output = line.match(/Tests run: (\d+), Failures: (\d+), Errors: (\d+), Skipped: (\d+), Time elapsed:/)
        match, total, fail, error, skip = output.to_a
        pass = total.to_i - fail.to_i - error.to_i - skip.to_i
        print "." * pass
        print "E" * error.to_i
        print "F" * fail.to_i
        print "S" * skip.to_i
        puts ""
      else
        # do nothing
      end
    end

    def guard_message(test_count, failure_count, error_count, skip_count, duration)
      message = "#{test_count} tests"
      if skip_count > 0
        message << " (#{skip_count} skipped)"
      end
      message << "\n#{failure_count} failures, #{error_count} errors"
      if test_count
        message << "\n\nFinished in #{duration}"
      end
      message
    end
  end
end
