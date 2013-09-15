# encoding: utf-8

require 'jruby-hornetq'

require 'hornetq/server'
HornetQ::Server.load_requirements
# HornetQ.require_jar('netty')
# HornetQ.require_jar('hornetq-core')

require 'hornetq/client'
# HornetQ.require_jar('hornetq-core-client')
# HornetQ.require_jar('netty')

require 'hornetq/client/connection'
require 'tigron/messaging/hornetq/ext/hornetq'

require 'jmx'

module Tigron
  module Messaging
    module HornetQ
      class ServerService
        def initialize
          # http://docs.jboss.org/jbossas/javadoc/7.1.2.Final/org/hornetq/core/server/HornetQServers.html
          @server = ::HornetQ::Server.create_server({
            uri: 'hornetq://localhost',
            data_directory: Rails.root.join('tmp/messaging').to_s,
            persistence_enabled: true,
            security_enabled: false,
            backup: false,

            mbean: java.lang.management.ManagementFactory.getPlatformMBeanServer
          })
        end

        def start(start_context)
          Tigron.logger.info "Starting HornetQ server..."
          # non blocking start
          @server.start
        end

        def stop(stop_context)
          Tigron.logger.info "Stopping HornetQ server..."
          @server.stop
          #failover_on_server_shutdown = true
          #server.stop(failover_on_server_shutdown)
        end

        def wait_util_started
          JMX::MBeanServer.new['org.hornetq:module=Core,type=Server'].version
        rescue JMX::NoSuchBeanError, javax.management.RuntimeMBeanException, java.lang.IllegalStateException
          Tigron.logger.info "Waiting for HornetQ server..."
          sleep 1

          retry
        end

        def value
          self
        end
      end
    end
  end
end

