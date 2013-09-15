# encoding: utf-8

module Tigron
  class Bootstrap
    def initialize!
      return unless Tigron.run_tigron?

      Rails.application.eager_load!

      initialize_registry
      show_banner
      load_all_properties
      replace_jul_logger
      initialize_cache_service
      initialize_web_service
      initialize_messaging_subsystem
      initialize_scheduler_subsystem
      initialize_services_subsystem
      finalize_initialization
    end

    private

    def replace_jul_logger
      # http://www.slf4j.org/api/org/slf4j/bridge/SLF4JBridgeHandler.html
      org.slf4j.bridge.SLF4JBridgeHandler.removeHandlersForRootLogger
      org.slf4j.bridge.SLF4JBridgeHandler.install
    end

    def initialize_registry
      TorqueBox::Registry.merge!({
        'service-registry' => Tigron::ServiceContainer.new,
        #'connection-factory' => :connection_factory,
        'connection-factory' => TorqueBox::Messaging::ConnectionFactory.new,
        'xa-connection-factory' => :xa_connection_factory,
        #'xa-connection-factory' => TorqueBox::Messaging::XaConnectionFactory.new,
        'runtime-injection' => :runtime_injection,
        'xa-ds-info' => :xa_ds_info,
        'service-target' => :service_target,
        'transaction-manager' => :transaction_manager
      })

      TorqueBox::Registry.merge!({
        'deployment-unit' => Tigron::DeploymentUnit.new(nil, 'jboss-as', TorqueBox::Registry['service-registry'])
      })

      TorqueBox::ServiceRegistry.service_registry = Tigron::DelegatingServiceRegistry.new(TorqueBox::Registry['service-registry'])

      at_exit do
        Tigron.logger.info "Shutting down service registry..."
        TorqueBox::Registry['service-registry'].shutdown
      end
    end

    def show_banner
      puts
      puts " _____ _"
      puts "|_   _(_) __ _ _ __ ___  _ __"
      puts "  | | | |/ _` | '__/ _ \\| '_ \\"
      puts "  | | | | (_| | | | (_) | | | |"
      puts "  |_| |_|\\__, |_|  \\___/|_| |_|"
      puts "         |___/ #{Tigron::VERSION}"
      puts

      Tigron.logger.info "Tigron Version: #{Tigron::VERSION}"
      Tigron.logger.debug "Configuration: #{Tigron.configuration.inspect}"
      Tigron.logger.info "Process ID: #{Process.pid}"
      Tigron.logger.debug "Number of threads: #{Thread.list.count}"
    end

    def load_all_properties
      Dir[File.join(File.expand_path('../../../..', __FILE__), 'config/*.properties')].each do |gem_property_file|
        user_property_file = Rails.root.join('config', File.basename(gem_property_file))
        property_file = user_property_file.exist? ? user_property_file : gem_property_file

        load_java_properties_file(property_file)
      end
    end

    def initialize_cache_service
      cache_info = Hash[[['class', Rails.cache.class.name]].concat(Rails.cache.instance_variables.map do |name|
        [name.to_s.gsub('@', ''), Rails.cache.instance_variable_get(name).to_s]
      end)]

      Tigron.add_service('cache', Tigron::ServiceValue.new(cache_info))
    end

    def initialize_web_service
      Tigron.add_service('web', Tigron::Web::Puma::Service.new)
    end

    def initialize_messaging_subsystem
      return unless Tigron.run_messaging?

      HornetQ.logger = Tigron.logger

      start_hornetq_server
      start_messaging_service

      Tigron.logger.debug "Number of threads: #{Thread.list.count}"
    end

    def start_hornetq_server
      return unless Tigron.run_hornetq_server?

      Tigron.add_service('hornetq_server', Tigron::Messaging::HornetQ::ServerService.new)
      Tigron.lookup('hornetq_server').wait_util_started
    end

    def start_messaging_service
      return unless Tigron.configuration[:messaging]

      Tigron.logger.info "Preparing messaging (processors) subsystem"
      Tigron.add_service('messaging', Tigron::Messaging::HornetQ::Service.new)
    end

    def initialize_scheduler_subsystem
      return unless Tigron.run_scheduler?

      Tigron.add_service('job_schedulizer', Tigron::Scheduler::Quartz::Service.new)
      Tigron.logger.debug "Number of threads: #{Thread.list.count}"
    end

    def initialize_services_subsystem
      return unless Tigron.run_services?

      Tigron.configuration.fetch(:services, {}).each do |(service_name, properties)|
        Tigron.register_service(service_name, properties)
      end
    end

    def finalize_initialization
      return unless Tigron.run_tigron?

      Tigron.logger.debug "Number of threads: #{Thread.list.count}"
      TorqueBox::Registry['service-registry'].dump_services
    end

    def load_java_properties_file(properties_file)
      Tigron.logger.debug "Loading properties file: #{properties_file}"

      input = java.io.FileInputStream.new(properties_file.to_s)
      props = java.util.Properties.new
      props.load(input)

      props.each do |(key, value)|
        Tigron.logger.debug "Setting property: #{key} => #{value}"
        java.lang.System.set_property(key, value)
      end

      props
    ensure
      input.close if input
    end
  end
end

