# encoding: utf-8

require 'tigron/scheduler/quartz/scheduler'
require 'tigron/scheduler/quartz/monitoring'

module Tigron
  module Scheduler
    module Quartz
      class Service
        def initialize
          @scheduler = Tigron::Scheduler::Quartz::Scheduler.new
        end

        def start(start_context)
          Tigron.logger.info "Starting scheduler"
          @scheduler.start

          Tigron.configuration.fetch(:jobs, {}).each do |(job_name, properties)|
            schedule_properties = properties.merge(disallow_concurrent: !properties[:concurrent])

            Tigron.logger.debug "scheduling #{job_name} with parameters: #{schedule_properties}"
            @scheduler.schedule(job_name, schedule_properties)

            Tigron.register_job(TorqueBox::Jobs::ScheduledJob.new(job_name.to_s))
          end
        end

        def stop(stop_context)
          Tigron.logger.info "Stopping scheduler"
          @scheduler.stop
          Tigron.logger.info "Scheduler stopped"
        end

        def value
          self
        end

        def version
          @scheduler.version
        end

        def list
          monitoring.jobs_list.map do |job|
            OpenStruct.new(job)
          end
        end

        def meta_data
          monitoring.meta_data
        end

        private

        def monitoring
          Monitoring.new(@scheduler.__send__(:scheduler))
        end
      end
    end
  end
end

