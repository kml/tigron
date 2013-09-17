# encoding: utf-8

module TorqueBox
  module Jobs
    class ScheduledJob
      SERVICE_STARTED = 'STARTED'.freeze
      SERVICE_STOPPED = 'STOPPED'.freeze

      attr_reader :name

      def initialize(name, service)
        @name = name
        @service = service
      end

      def started?
        status == SERVICE_STARTED
      end

      def stop
        @service.scheduler.pause(name)
      end

      def start
        @service.scheduler.resume(name)
      end

      def status
        return SERVICE_STOPPED if job_trigger_state == :paused
        SERVICE_STARTED
      end

      private

      def job_trigger_state
        trigger_key = @service.scheduler.trigger_key(@name)
        trigger_state = @service.__send__(:quartz_scheduler).getTriggerState(trigger_key)

        Monitoring.trigger_state_sym(trigger_state)
      end
    end
  end
end

