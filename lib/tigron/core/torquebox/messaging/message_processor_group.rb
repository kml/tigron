# encoding: utf-8

module TorqueBox
  module Messaging
    class MessageProcessorGroup
      def initialize(destination_name, processor_name, processor_options)
        @destination_name = destination_name
        @processor_name = processor_name
        @processor_options = processor_options
      end

      def update_concurrency(size)
        raise 'changing concurrency is not supported'
      end

      def concurrency
        @processor_options[:concurrency]
      end

      def name
        "#{destination_name}.#{message_processor_class}"
      end

      def destination_name
        @destination_name
      end

      def message_processor_class
        @processor_options[:processor]
      end

      def message_selector
        @processor_options[:selector].to_s
      end

      def durable
        @processor_options[:durable]
      end

      def synchronous
        @processor_options[:synchronous]
      end

      def status
        'STARTED'
      end

      def start(start_context = nil)
      end

      def stop(stop_context = nil)
      end

      def value
        self
      end
    end
  end
end

