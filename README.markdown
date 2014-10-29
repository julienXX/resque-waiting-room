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

## Testing

We include a matcher

    require 'spec/support/matchers'

    describe MyJob do
      it 'is rate limited' do
        MyJob.should be_only_performed(times: 100, period: 300)
      end
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Thanks to the following people for helping out ##

- Thomas Devol [@socialchorus](https://github.com/socialchorus) for adding the RSpec matcher
- Max Dunn [@maxdunn210](https://github.com/maxdunn210) for making me switch Resque 2 specific code in it's own branch
- Jeff Durand [@johnnyiller](https://github.com/johnnyiller) for the update of has_remaining_performs_key using the latest form set

[rq]: http://github.com/resque/resque

[![Build Status](https://travis-ci.org/julienXX/resque-waiting-room.png)](https://travis-ci.org/julienXX/resque-waiting-room) [![Code Climate](https://codeclimate.com/github/julienXX/resque-waiting-room.png)](https://codeclimate.com/github/julienXX/resque-waiting-room)
