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

            return new(queue, payload) unless repushed_in_waiting_room
          end
          return nil
        else
          origin_reserve(queue)
        end
      end

    end
  end
end
