# encoding: utf-8

require 'quartz/cron_job'
require 'quartz/scheduler'

module Tigron
  module Scheduler
    module Quartz
      class Scheduler
        include ::Quartz::Scheduler::InstanceMethods

        alias schedule_quartz schedule

        def schedule(name, options)
          schedule_quartz(name, options, nil)
        end

        alias start run

        def version
          scheduler.meta_data.version
        end

        def register_job(name, options, block)
          Registry.add_job_info(name, options[:job], options[:config])
        end
      end
    end
  end
end

