# Guard::Maven

A simple Guard for automatically running tests while working on a Maven project.

## Installation

Add this line to your application's Gemfile:

    gem 'guard-maven'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install guard-maven

## Usage

Run `guard init maven` to setup the Guardfile with a base watcher. Modify as necessary to match your project.

### Options

* __verbose__ _default: false_ Output ALL of the regular test output from the Maven tests
* __all_on_start__ _default: false_ Run all of the tests when Guard starts

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
