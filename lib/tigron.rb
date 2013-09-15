# encoding: utf-8

require 'tigron/core'
require 'tigron/messaging/hornetq'
require 'tigron/scheduler/quartz'
require 'tigron/web/puma'

module Tigron
  def self.run_tigron?
    java.lang.System.get_property('tigron.enabled') == 'true'
  end

  def self.run_scheduler?
    subsystem_enabled?(:scheduler)
  end

  def self.run_messaging?
    subsystem_enabled?(:messaging)
  end

  def self.run_hornetq_server?
    subsystem_enabled?(:messaging) # subsystem_enabled?(:hornetq_server)
  end

  def self.run_services?
    subsystem_enabled?(:services)
  end

  def self.subsystem_enabled?(subsystem)
    run_tigron? && java.lang.System.get_property("tigron.#{subsystem}.enabled") != 'false'
  end

  def self.logger
    @logger ||= HornetQ.ruby_logger(::Logger::DEBUG, Rails.root.join('log/tigron.log').to_s).tap do |l|
      l.formatter = Logger::Formatter.new
    end
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.configuration
    @configuration ||= Tigron::Configuration.load(Rails.root.join('config/torquebox.yml'))
  end

  def self.application_name
    Rails.application.class.parent_name
  end

  def self.initialize!
    Tigron::Bootstrap.new.initialize!
  end

  def self.scheduler
    lookup('job_schedulizer')
  end

  def self.messaging
    lookup('messaging')
  end

  def self.register_job(job)
    value = ServiceValue.new(job)
    service_name = TorqueBox::MSC.deployment_unit.service_name.append('scheduled_job').append(job.name)
    service_builder = TorqueBox::Registry['service-registry'].add_service(service_name, value)
    service_builder.install
  end

  def self.register_service(name, properties)
    service = ServiceProxy.new(name.to_s, properties)

    service_name = TorqueBox::Service.__send__(:service_prefix).append(service.name).append('create')
    service_builder = TorqueBox::Registry['service-registry'].add_service(service_name, service)
    service_builder.install
  end

  def self.lookup(name)
    TorqueBox::ServiceRegistry.lookup(TorqueBox::MSC.deployment_unit.service_name.append(name))
  end

  def self.add_service(name, service)
    service_name = name.respond_to?(:append) ? name : TorqueBox::MSC.deployment_unit.service_name.append(name)

    service_builder = TorqueBox::Registry['service-registry'].add_service(service_name, service)
    service_builder.install
  end
end

require 'tigron/version'
require 'tigron/engine'

