Resque Waiting Room
===================

A [Resque][rq] plugin. Requires Resque >= 1.19 and a >= 1.9 Ruby (MRI, JRuby or Rubinius).

If you want to limit the number of performs of a job for a given period, extend it
with this module.

## Installation

Add this line to your application's Gemfile:

    gem 'resque-waiting-room'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resque-waiting-room

## Usage

#### Example -- 10 jobs processed every 30 seconds max

    require 'resque/plugins/waiting_room'

    class UpdateDataFromExternalAPI
      extend Resque::Plugins::WaitingRoom

      # This job can be performed 10 times every 30 seconds
      can_be_performed times: 10, period: 30

      def self.perform(repo_id)
        blah
      end
    end

If 10 UpdateDataFromExternalAPI jobs have been performed in 20
seconds, for the next 10 seconds UpdateDataFromExternalAPI jobs
will be placed in the waiting_room queue and processed when possible.
When the first 30 seconds are elapsed, the counter is set back to 0
and 10 jobs can be performed again.
You got to manually tweak the queue names in your workers though.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[rq]: http://github.com/julienXX/resque

[![Build Status](https://travis-ci.org/julienXX/resque-waiting-room.png)](https://travis-ci.org/julienXX/resque-waiting-room)

[![Code Climate](https://codeclimate.com/github/julienXX/resque-waiting-room.png)](https://codeclimate.com/github/julienXX/resque-waiting-room)
