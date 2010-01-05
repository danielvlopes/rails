require 'active_support/secure_random'
require 'active_support/core_ext/module/delegation'

module ActiveSupport
  module Notifications
    class Instrumenter
      attr_reader :id

      def initialize(notifier)
        @id = unique_id
        @notifier = notifier
      end

      # Instrument the given block by measuring the time taken to execute it
      # and publish it.
      def instrument(name, payload={}, add_result=false)
        time = Time.now
        result = yield if block_given?
        payload.merge!(:result => result) if add_result
        @notifier.publish(name, time, Time.now, @id, payload)
        result
      end

      # The same as instrument, but adds the result as payload.
      def instrument!(name, payload={}, &block)
        instrument(name, payload, true, &block)
      end

      private
        def unique_id
          SecureRandom.hex(10)
        end
    end

    class Event
      attr_reader :name, :time, :end, :transaction_id, :payload

      def initialize(name, start, ending, transaction_id, payload)
        @name           = name
        @payload        = payload.dup
        @time           = start
        @transaction_id = transaction_id
        @end            = ending
      end

      def duration
        @duration ||= 1000.0 * (@end - @time)
      end

      def parent_of?(event)
        start = (self.time - event.time) * 1000
        start <= 0 && (start + duration >= event.duration)
      end
    end
  end
end