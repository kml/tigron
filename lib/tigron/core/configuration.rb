# encoding: utf-8

require 'yaml'
require 'i18n/core_ext/hash' # deep_symbolize_keys

module Tigron
  class Configuration
    def self.load(file)
      new(YAML.load_file(file.to_s)).config
    end

    attr_reader :config

    def initialize(configuration)
      @config = configuration.deep_symbolize_keys
      normalize_environment
      normalize_messaging
      normalize_jobs
      normalize_services
    end

    private

    def normalize_environment
      if config[:environment]
        config.fetch(:environment, []).each do |(name, value)|
          ENV[name.to_s] = value
        end
      end

      ENV['TORQUEBOX_APP_NAME'] = Tigron.application_name unless ENV['TORQUEBOX_APP_NAME']
      ENV['TORQUEBOX_APP_TYPE'] = 'rails' unless ENV['TORQUEBOX_APP_TYPE']
    end

    def normalize_messaging
      if config[:messaging]
        config[:messaging].each do |(queue_name, properties)|
          properties.each do |(processor_name, processor_options)|
            processor_options[:processor] = processor_name.to_s.constantize
            processor_options[:concurrency] ||= 1
            Integer(processor_options[:concurrency])
            processor_options[:selector] ||= ""

            raise "singleton: true is not supported" if processor_options[:singleton] == true
            processor_options[:singleton] = false if processor_options[:singleton].nil?

            raise "durable: true is not supported" if processor_options[:durable] == true
            processor_options[:durable] = false if processor_options[:durable].nil?

            raise "xa: true is not supported" if processor_options[:xa] == true
            processor_options[:xa] = false if processor_options[:xa].nil?

            raise "stopped: true is not supported" if processor_options[:stopped] == true
            processor_options[:stopped] = false if processor_options[:stopped].nil?

            raise "synchronous: true is not supported" if processor_options[:synchronous] == true
            processor_options[:synchronous] = false if processor_options[:synchronous].nil?
          end
        end
      end

      if config[:queues]
        config[:queues].each do |(queue_name, properties)|
          properties[:durable] = false if properties[:durable].nil?
          properties[:address] = queue_name unless properties[:address]
        end
      end

      backgroundable_concurrency = 1
      backgroundable_is_durable = true

      if config[:tasks] && config[:tasks].has_key?(:Backgroundable)
        if config[:tasks][:Backgroundable].has_key?(:concurrency)
          backgroundable_concurrency = Integer(config[:tasks][:Backgroundable][:concurrency])
        end

        if config[:tasks][:Backgroundable].has_key?(:durable)
          backgroundable_is_durable = !!config[:tasks][:Backgroundable][:durable]
        end
      end

      if backgroundable_concurrency > 0
        backgroundable_queue = TorqueBox::Messaging::Task.queue_name("torquebox_backgroundable").to_sym
        #backgroundable_queue = :"/queues/torquebox/#{ENV['TORQUEBOX_APP_NAME']}/tasks/torquebox_backgroundable"
        config[:queues] ||= {}
        config[:queues][backgroundable_queue] = {}
        config[:queues][backgroundable_queue][:address] = backgroundable_queue
        config[:queues][backgroundable_queue][:durable] = backgroundable_is_durable

        backgroundable_processor_name = TorqueBox::Messaging::BackgroundableProcessor.name.to_sym

        config[:messaging] ||= {}
        config[:messaging][backgroundable_queue] = {
          :Backgroundable => {
            processor: TorqueBox::Messaging::BackgroundableProcessor,
            concurrency: backgroundable_concurrency,
            selector: "JMSCorrelationID is null"
          }
        }
      end
    end

    def normalize_jobs
      if config[:jobs]
        config[:jobs].each do |(job_name, properties)|
          unless properties[:job].is_a?(Class)
            properties[:job] = properties[:job].to_s.constantize
          end

          properties[:concurrent] = false if properties[:concurrent].nil?
          properties[:concurrent] = !!properties[:concurrent]
        end
      end
    end

    def normalize_services
      if config[:services]
        config[:services].each do |(service_name, properties)|
          unless properties.is_a?(Hash)
            config[:services][service_name] = {}
            properties = config[:services][service_name]
          end

          properties[:service] = service_name unless properties[:service]

          unless properties[:service].is_a?(Class)
            klass = properties[:service].to_s.constantize
            properties[:service] = klass
          end
        end
      end
    end
  end
end

