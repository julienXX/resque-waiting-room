module Resque
  module Plugins
    module WaitingRoom
      class MissingParams < RuntimeError; end

      def can_be_performed(params)
        raise MissingParams unless params.is_a?(Hash) && params.keys.sort == [:period, :times]

        @period ||= params[:period]
        @max_performs ||= params[:times].to_i
      end

      def waiting_room_redis_key
        [self.to_s, "remaining_performs"].compact.join(":")
      end

      def before_perform_waiting_room(*args)
        key = waiting_room_redis_key

        if has_remaining_performs_key?(key)
          performs_left = Resque.redis.decrby(key, 1).to_i
          ensure_has_expireation(key)

          if performs_left < 1
            Resque.push 'waiting_room', class: self.to_s, args: args
            raise Resque::Job::DontPerform
          end
        end
      end

      def has_remaining_performs_key?(key)
        # Redis SETNX: sets the keys if it doesn't exist, returns true if key was created
        new_key = Resque.redis.setnx(key, @max_performs - 1)
        Resque.redis.expire(key, @period) if new_key

        return !new_key
      end

      def repush(*args)
        key = waiting_room_redis_key
        value = Resque.redis.get(key)
        no_performs_left = value && value != "" && value.to_i <= 0
        Resque.push 'waiting_room', class: self.to_s, args: args if no_performs_left

        return no_performs_left
      end

      def ensure_has_expireation(key)
        Resque.redis.expire(key, @period) if Resque.redis.ttl(key) == -1
      end
    end
  end
end
