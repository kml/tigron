# encoding: utf-8

module Tigron
  module Scheduler
    module Quartz
      class JobInfo
        attr_accessor :name
        attr_accessor :job
        attr_accessor :options

        def initialize(name, job, options)
          self.name = name
          self.job = job
          self.options = options
        end

        def initialize_and_execute(context)
          new_instance.run
        end

        def new_instance
          if job.instance_method(:initialize).arity.abs == 1
            return job.new(options)
          end

          job.new
        end
      end
    end
  end
end

