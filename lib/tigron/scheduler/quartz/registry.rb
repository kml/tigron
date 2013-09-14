# encoding: utf-8

require 'singleton'

module Tigron
  module Scheduler
    module Quartz
      class Registry
        include Singleton

        def initialize
          @options = {}
          @jobs = {}
        end

        def add_job_info(name, job, config)
          unless job.instance_methods.include?(:run)
            raise 'Job class should have run instance method'
          end

          @jobs[name.to_s] = job
          @options[name.to_s] = config || {}
        end

        def find(job_name)
          JobInfo.new(job_name, @jobs[job_name], @options[job_name])
        end

        def self.add_job_info(*args)
          instance.add_job_info(*args)
        end

        def self.find(job_name)
          instance.find(job_name)
        end
      end
    end
  end
end

