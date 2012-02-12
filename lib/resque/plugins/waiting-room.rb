require 'resque'

module Resque
  class Job
    class <<self
      alias_method :origin_reserve, :reserve

      def reserve(queue)
        if queue =~ /^waiting_room/ && Resque.size(queue) > 0
          payload = Resque.pop(queue)
          if payload
            klass = constantize(payload['class'])
            repushed_in_waiting_room = klass.repush(*payload['args'])

            unless repushed_in_waiting_room
              return new(queue, payload)
            end
          end
          return nil
        else
          origin_reserve(queue)
        end
      end

    end
  end

  module Plugins
    module WaitingRoom
      def can_be_performed(options={})
        @period = options[:period]
        @max_performs = options[:times].to_i
      end

      def waiting_room_redis_key
        [self.to_s, "remaining_performs"].compact.join(":")
      end

      def before_perform_waiting_room(*args)
        key = waiting_room_redis_key

        if count_key(key, @max_performs)
          performs_left = Resque.redis.decrby(key, 1).to_i

          if performs_left < 1
            Resque.push 'waiting_room', :class => self.to_s, :args => args
            raise Resque::Job::DontPerform
          end
        end
      end

      def count_key(key, number_of_performs)
        # Redis SETNX: sets the keys if it doesn't exist, returns true if key exist
        key_created = !Resque.redis.setnx(key, number_of_performs - 1)
        # Redis EXPIRE: returns TTL or -1 if key doesn't exist/has no ttl
        Resque.redis.expire(key, @period) if key_created

        return key_created
      end

      def repush(*args)
        has_restrictions = false
        key = waiting_room_redis_key
        value = Resque.redis.get(key)
        no_performs_left = value && value != "" && value.to_i <= 0
        Resque.push 'waiting_room', class: self.to_s, args: args if no_performs_left

        return no_performs_left
      end

    end
  end
end

