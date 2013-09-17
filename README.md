# Tigron

TorqueBox like application server inside single JRuby runtime.
Beware: Hybrid may have EMOTIONAL & BEHAVIOURAL PROBLEMS

## Installation

Add this line to your application's Gemfile:

    gem 'quartz-jruby', git: 'git://github.com/kml/quartz-jruby.git', branch: 'tigron', require: false
    gem 'jruby-hornetq', git: 'git://github.com/kml/jruby-hornetq.git', branch: 'hornetq-2.3.0.cr1', require: false
    gem 'tigron', git: 'git://github.com/kml/tigron.git'

And then execute:

    $ bundle install --binstubs

## Usage

Run:

    $ JAVA_OPTS="-Dtigron.enabled=true" ./bin/puma

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

