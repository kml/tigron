# encoding: utf-8

require 'tigron/scheduler/quartz'
java_import org.quartz.impl.matchers.GroupMatcher
java_import org.quartz.Trigger

module Tigron
  module Scheduler
    module Quartz
      class Monitoring
        def initialize(scheduler)
          @scheduler = scheduler
        end

        def all
          {
            scheduler_name: @scheduler.scheduler_name,
            is_started: @scheduler.is_started,
            is_in_standby_mode: @scheduler.is_in_standby_mode,
            is_shutdown: @scheduler.is_shutdown,
            jobs: jobs_list,
            meta_data: meta_data,
          }
        end

        def jobs_list
          jobs = []

          job_group_names.each do |group_name|
            jobs.concat(keys_with_details(group_name))
          end

          jobs
        end

        def job_group_names
          @scheduler.job_group_names.to_a
        end

        def meta_data
          # http://quartz-scheduler.org/api/2.0.0/org/quartz/SchedulerMetaData.html
          meta = @scheduler.meta_data

          resp = %w[summary scheduler_name scheduler_instance_id scheduler_class running_since
          number_of_jobs_executed is_scheduler_remote is_started
          is_in_standby_mode is_shutdown job_store_class is_job_store_supports_persistence
          is_job_store_clustered thread_pool_size version].each_with_object({}) do |m, object|
            object[m.to_sym] = meta.send(m)
          end

          resp[:scheduler_class] = resp[:scheduler_class].to_s
          resp[:running_since] = resp[:running_since].to_s
          resp[:job_store_class] = resp[:job_store_class].to_s

          resp
        end

        def job_keys(group_name)
          @scheduler.getJobKeys(GroupMatcher.jobGroupEquals(group_name)).to_a
        end

        def keys_with_details(group_name)
          job_keys(group_name).map do |job_key|
            {
              name: job_key.name,
              group: job_key.group,
              cron_trigger: cron_trigger_details(job_key),
              details: job_detail(job_key),
              _info: {
                name: job_info(job_key).name,
                job: job_info(job_key).job.to_s,
                options: job_info(job_key).options
              }
            }
          end
        end

        def job_info(job_key)
          Registry.find(job_key.name)
        end

        def cron_trigger(job_key)
          @scheduler.getTriggersOfJob(job_key).to_a.first
        end

        def cron_trigger_details(job_key)
          # http://quartz-scheduler.org/api/2.0.0/org/quartz/impl/triggers/CronTriggerImpl.html
          {
            cron_expression: cron_trigger(job_key).cron_expression,
            next_fire_time: cron_trigger(job_key).next_fire_time.to_s,
            expresion_summary: cron_trigger(job_key).expression_summary,
            description: cron_trigger(job_key).description,
            state: self.class.trigger_state_sym(@scheduler.getTriggerState(cron_trigger(job_key).key))
          }
        end

        def self.trigger_state_sym(trigger_state)
          case trigger_state
          when Trigger::TriggerState::BLOCKED then :blocked
          when Trigger::TriggerState::COMPLETE then :complete
          when Trigger::TriggerState::ERROR then :error
          when Trigger::TriggerState::NONE then :none
          when Trigger::TriggerState::NORMAL then :normal
          when Trigger::TriggerState::PAUSED then :paused
          end
        end

        def job_detail(job_key)
          # http://quartz-scheduler.org/api/2.0.0/org/quartz/JobDetail.html
          job_detail = @scheduler.getJobDetail(job_key)

          {
            description: job_detail.description,
            job_class: job_detail.job_class.to_s,
            is_durable: job_detail.is_durable,
            is_concurrent_execution_disallowed: job_detail.isConcurrentExectionDisallowed,
            is_durable: job_detail.is_durable,

            is_persist_job_data_after_execution: job_detail.isPersistJobDataAfterExecution,
            requests_recovery: job_detail.requestsRecovery
          }
        end
      end
    end
  end
end

