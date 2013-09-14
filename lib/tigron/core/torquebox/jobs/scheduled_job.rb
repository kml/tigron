# encoding: utf-8

module TorqueBox
  module Jobs
    class ScheduledJob
      STATUS_STARTED = 'STARTED'.freeze

      attr_reader :name

      def initialize(name)
        @name = name
      end

      def started?
        true
      end

      def stop
      end

      def status
        STATUS_STARTED
      end
    end
  end
end

