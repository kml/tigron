# encoding: utf-8

require 'jmx'
require 'jmx/util/string_utils'
require 'json'

module Tigron
  module Messaging
    module HornetQ
      class Monitoring
        include JMX::StringUtils

        def initialize(hornetq_jmx)
          @hornetq_jmx = hornetq_jmx
        end

        def list
          hornetq = client['org.hornetq:module=Core,type=Server']
          queue_names = hornetq.queue_names.map { |name| name }

          queue_names.map do |name|
            begin
              queue_control = client["org.hornetq:module=Core,type=Queue,address=\"#{name}\",name=\"#{name}\""]

              OpenStruct.new({
                name: queue_control.name,
                durable: queue_control.durable ? 'durable' : 'non-durable',
                status: queue_control.paused ? 'Paused' : 'Running',
                messages: queue_control.message_count,
                delivering: queue_control.delivering_count,
                scheduled: queue_control.scheduled_count,
                added: queue_control.messages_added,
                consumers: queue_control.consumer_count
              })
            rescue JMX::NoSuchBeanError
              nil
            end
          end.compact
        rescue JMX::NoSuchBeanError
          []
        end

        def client
          @hornetq_jmx
        end

        def find(queue_name)
          queue_control = client["org.hornetq:module=Core,type=Queue,address=\"#{queue_name}\",name=\"#{queue_name}\""]
          queue_settings = queue_control.attributes.map do |attribute|
            value = queue_control.__send__(snakecase(attribute))

            [attribute, value]
          end
          address_name = queue_control.address
          address = client["org.hornetq:module=Core,type=Address,name=\"#{address_name}\""]
          address_settings = address.attributes.map do |attribute|
            next nil if attribute == 'Roles'
            value = address.__send__(snakecase(attribute))

            [attribute, Array(value).map{|el| el.to_s}.join(', ')]
          end.compact

          hornetq = client['org.hornetq:module=Core,type=Server']

          settings_json = JSON.parse(hornetq.getAddressSettingsAsJSON(address_name)).to_a

          OpenStruct.new({
            queue_name: queue_name,
            queue_settings: queue_settings,
            address_name: address_name,
            address_settings: address_settings,
            settings_json: settings_json
          })
        end
      end
    end
  end
end

