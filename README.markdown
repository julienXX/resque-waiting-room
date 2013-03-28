Resque Waiting Room
===================

A [Resque][rq] plugin. Requires Resque 1.19.0.

If you want to limit the number of performs of a job for a given period, extend it
with this module.

For example:

    require 'resque/plugins/waiting_room'

    class UpdateDataFromExternalAPI
      extend Resque::Plugins::WaitingRoom

      # This job can be performed 10 times every 30 seconds
      can_be_performed times: 10, period: 30

      def self.perform(repo_id)
        blah
      end
    end

If 10 UpdateDataFromExternalAPI jobs have been performed in less than
30 seconds, next job will be placed placed in the waiting_room queue
and processed when possible.

[rq]: http://github.com/julienXX/resque

[![Code Climate](https://codeclimate.com/github/julienXX/resque-waiting-room.png)](https://codeclimate.com/github/julienXX/resque-waiting-room)
