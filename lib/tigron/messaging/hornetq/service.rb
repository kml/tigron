# encoding: utf-8

require 'tigron/messaging/hornetq/ext/hornetq/client/transacted_session_pool'
require 'tigron/messaging/hornetq/worker_pool'
require 'tigron/messaging/hornetq/monitoring'

require 'tigron/core/torquebox/messaging/message_processor_group'

module Tigron
  module Messaging
    module HornetQ
      class Service
        def initialize
          @connection = ::HornetQ::Client::Connection.new(uri: hornetq_uri)

          @session_pool = ::HornetQ::Client::TransactedSessionPool.new(@connection, {
            pool_name: 'processors_pool',
            pool_size: pool_size,
            pool_warn_timeout: 5,
            pool_logger: Tigron.logger
          })
        end

        def start(start_context)
          log_hornetq_version
          create_queues
          register_groups
          start_workers
        end

        def stop(stop_context)
          Tigron.logger.info "HornetQ: Closing session_pool"
          @session_pool.close

          Tigron.logger.info "HornetQ: Closing connection"
          @connection.close
          Tigron.logger.info "HornetQ: Connection closed!"
        end

        def value
          self
        end

        def workers
          @workers.each_with_object([]) do |pool, statuses|
            pool.status.each do |status|
              statuses << OpenStruct.new(status.merge({
                queue: pool.queue,
                processor: pool.processor,
                name: pool.processor_name
              }))
            end
          end
        end

        def message_processors
          Tigron.configuration.fetch(:messaging, {}).each_with_object([]) do |(queue_name, properties), processors|
            properties.each do |(processor_name, processor_options)|
              processors << OpenStruct.new({
                name: processor_name.to_s,
                destination: queue_name,
                concurrency: processor_options[:concurrency]
              })
            end
          end
        end

        def version
          hornetq_core_server.version
        end

        def log_hornetq_version
          Tigron.logger.info "HornetQ Version: #{version}"
        end

        def create_queues
          return unless Tigron.configuration[:queues]

          Tigron.logger.info "Loading queues settings"

          ::HornetQ::Client::Connection.session(hornetq_uri) do |session|
            Tigron.configuration[:queues].each do |(queue_name, properties)|
              Tigron.logger.debug "queue_name: #{queue_name} properties: #{properties}"

              begin
                session.create_queue(
                  "jms.queue.#{properties[:address]}",
                  "jms.queue.#{queue_name}",
                  properties[:durable]
                )
              rescue org.hornetq.api.core.HornetQQueueExistsException => exception
                Tigron.logger.warn "#{self.class.name} WARN: #{exception.message}"
                next
              end
            end
          end
        end

        def register_groups
          Tigron.configuration[:messaging].each do |(queue_name, properties)|
            queue_name = "jms.queue.#{queue_name}"
            properties.each do |(processor_name, processor_options)|
              messaging_service_name = TorqueBox::Messaging::MessageProcessor.__send__(:messaging_service_name)

              destination_name = queue_name
              class_name = processor_options[:processor]
              service_name = messaging_service_name.append("#{destination_name}.#{class_name}")

              Tigron.add_service(service_name, TorqueBox::Messaging::MessageProcessorGroup.new(queue_name, processor_name, processor_options))
            end
          end
        end

        def start_workers
          @workers = []

          Tigron.configuration[:messaging].each do |(queue_name, properties)|
            queue_name = "jms.queue.#{queue_name}"
            properties.each do |(processor_name, processor_options)|
              Tigron.logger.debug "processor_class: #{processor_options[:processor]} concurrency: #{processor_options[:concurrency]} selector: #{processor_options[:selector]}"

              @workers << Tigron::Messaging::HornetQ::WorkerPool.new(
                queue_name,
                processor_options[:processor],
                processor_name,
                processor_options[:concurrency],
                @session_pool,
                processor_options[:selector]
              )
            end
          end
        end

        def list
          Monitoring.new(hornetq_jmx).list
        end

        def find(queue_name)
          Monitoring.new(hornetq_jmx).find(queue_name)
        end

        private

        def hornetq_host
          'localhost'
        end

        def hornetq_port
          5445
        end

        def hornetq_uri
          "hornetq://#{hornetq_host}:#{hornetq_port}"
        end

        def hornetq_jmx
          # embedded
          return JMX::MBeanServer.new

          # HornetQ standalone
          #return JMX.connect(port: 3333)
          #return JMX::MBeanServer.new("service:jmx:rmi:///jndi/rmi://localhost:3333/jmxrmi")

          # TB: http://torquebox.org/documentation/2.3.2/additional-resources.html#visualvm
          # jboss-client.jar
          #return JMX::MBeanServer.new("service:jmx:remoting-jmx://127.0.0.1:4447", 'user', 'password')
        end

        def hornetq_core_server
          hornetq_jmx['org.hornetq:module=Core,type=Server']
        end

        def pool_size
          size = 0

          Tigron.configuration[:messaging].each do |(queue_name, properties)|
            properties.each do |(processor_name, processor_options)|
              size += (processor_options[:concurrency] || 1)
            end
          end

          size
        end
      end
    end
  end
end

