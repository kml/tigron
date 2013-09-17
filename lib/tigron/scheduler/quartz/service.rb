# encoding: utf-8

require 'tigron/scheduler/quartz/scheduler'
require 'tigron/scheduler/quartz/monitoring'

module Tigron
  module Scheduler
    module Quartz
      class Service
        attr_reader :scheduler

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

            Tigron.register_job(TorqueBox::Jobs::ScheduledJob.new(job_name.to_s, self))
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

        def create_job(class_name, cron, timeout, name, description, config, singleton, stopped)
          raise "changing timeout is not supported" if timeout != '0s'
          # singleton is silently ignored

          @scheduler.schedule(name, {
            job: clas_name.to_s.constantize,
            config: config,
            disallow_concurrent: true,
            description: description,
            cron: cron
          })

          if stopped
            @scheduler.pause(name)
          end

          Tigron.register_job(TorqueBox::Jobs::ScheduledJob.new(name.to_s, self))

          java.util.concurrent.CountDownLatch.new(0)
        end

        # TODO
        def create_at_job(class_name, start, work_until, every, repeat, timeout, name, description, config, singleton)
          raise 'at jobs are not supported'

          # raise "changing timeout is not supported" if timeout != '0s'

          # start
          # work_until
          # every
          # repeat

          # @scheduler.schedule(name, {
          #   job: clas_name.to_s.constantize,
          #   config: config,
          #   disallow_concurrent: true,
          #   description: description
          # })

          # java.util.concurrent.CountDownLatch.new(0)
        end

        def remove_job(name)
          @scheduler.unschedule(name)
          Tigron.unregister_job(name)

          java.util.concurrent.CountDownLatch.new(0)
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
          Monitoring.new(quartz_scheduler)
        end

        def quartz_scheduler
          @scheduler.__send__(:scheduler)
        end
      end
    end
  end
end

