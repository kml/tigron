# encoding: utf-8

require 'quartz/cron_job'
require 'tigron/scheduler/quartz/registry'

module Quartz
  class CronJob
    private

    def initialize_and_execute(context)
      Tigron::Scheduler::Quartz::Registry.find(context.job_detail.name).initialize_and_execute(context)
    end
  end
end

