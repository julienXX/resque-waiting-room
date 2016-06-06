module Resque
  module Plugins
    module WaitingRoom
      class MissingParams < RuntimeError; end

      def can_be_performed(params)
        raise MissingParams unless params.is_a?(Hash) && params.keys.sort == [:period, :times]

        @period ||= params[:period]
        @max_performs ||= params[:times].to_i
      end

      def waiting_room_redis_key(*args)
        [self.to_s, 'remaining_performs'].compact.join(':')
      end

      def before_perform_waiting_room(*args)
        key = waiting_room_redis_key(args)
        return unless remaining_performs_key?(key)

        performs_left = Resque.redis.decrby(key, 1).to_i
        if performs_left < 1
          Resque.push 'waiting_room', class: self.to_s, args: args
          raise Resque::Job::DontPerform
        end
      end

      def remaining_performs_key?(key)
        # if true then we will only set a key if it doesn't exist
        # if false then we will set the key regardless.  If we have
        # a negative number then redis either doesn't know about the key
        # or it doesn't have a ttl, either way we want to create a new key
        # with a new ttl.
        nx = Resque.redis.ttl(key).to_i > 0

        # Redis SET: with the ex and nx option  sets the keys if it doesn't exist,
        # returns true if key was created redis => 2.6 required
        # http://redis.io/commands/SET
        !Resque.redis.set(key, @max_performs - 1, ex: @period, nx: nx)
      end

      def repush(*args)
        key = waiting_room_redis_key(args)
        value = Resque.redis.get(key)
        no_performs_left = value && value != '' && value.to_i <= 0
        Resque.push 'waiting_room', class: self.to_s, args: args if no_performs_left

        return no_performs_left
      end
    end
  end
end
