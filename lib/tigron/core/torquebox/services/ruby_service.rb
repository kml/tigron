# encoding: utf-8

module TorqueBox
  module Services
    class RubyService
      STATUS_STARTED = 'STARTED'.freeze
      STATUS_STOPPED = 'STOPPED'.freeze

      def initialize(service)
        @service = service
      end

      def name
        @service.name
      end

      def started?
        @service.started?
      end

      def status
        @service.started? ? STATUS_STARTED : STATUS_STOPPED
      end

      def stop
        @service.service.stop
      end

      def ruby_class_name
        @service.service.class.name
      end
    end
  end
end

