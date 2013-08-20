require 'guard'
require 'guard/guard'

module Guard
  class Maven < Guard

    # Initializes a Guard plugin.
    # Don't do any work here, especially as Guard plugins get initialized even if they are not in an active group!
    #
    # @param [Array<Guard::Watcher>] watchers the Guard plugin file watchers
    # @param [Hash] options the custom Guard plugin options
    # @option options [Symbol] group the group this Guard plugin belongs to
    # @option options [Boolean] any_return allow any object to be returned from a watcher
    #
    def initialize(watchers = [], options = {})
      super
      @options = options
    end

    # Called once when Guard starts. Please override initialize method to init stuff.
    #
    # @raise [:task_has_failed] when start has failed
    # @return [Object] the task result
    #
    def start
      run_all if @options[:all_on_start]
    end

    # Called when just `enter` is pressed
    # This method should be principally used for long action like running all specs/tests/...
    #
    # @raise [:task_has_failed] when run_all has failed
    # @return [Object] the task result
    #
    def run_all
      system('mvn', 'clean', 'test')
      notify('')
    end

    # Default behaviour on file(s) changes that the Guard plugin watches.
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_change has failed
    # @return [Object] the task result
    #
    def run_on_changes(paths)
      puts paths
      # for now run all
      if paths.include? 'all'
        run_all
      else
        system('mvn', 'clean', 'test', '-Dtest=' + paths.join(','))
        notify('\n' + paths.join('\n'))
      end
    end

    private

    def notify(name)
      title = 'mvn test'
      message = "mvn test #{$?.success? ? 'passed' : 'failed'}#{name}"
      image = $?.success? ? :success : :failed
      Notifier.notify(message, title: title, image: image)
    end

  end
end
