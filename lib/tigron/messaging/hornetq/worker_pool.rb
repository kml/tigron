# encoding: utf-8

require 'tigron/messaging/hornetq/torquebox_message_adapter'

module Tigron
  module Messaging
    module HornetQ
      class WorkerPool
        attr_reader :queue, :processor, :processor_name, :concurrency

        def initialize(queue, processor, processor_name, concurrency, session_pool, filter)
          @queue = queue
          @processor = processor
          @processor_name = processor_name
          @concurrency = concurrency
          @filter = filter

          @workers = (1..concurrency).map do |i|
            address = queue
            name = "#{address}-#{queue}-#{i}"
            Tigron.logger.info "#{self.class.name}: Starting worker: #{name}"

            spawn_worker(queue, processor, name, session_pool)
          end
        end

        def status
          @workers.map do |thread|
            {
              status: thread[:status],
              started_at: thread[:started_at],
              message_id: thread[:message_id],
              failed: thread[:failed],
              processed: thread[:processed]
            }
          end
        end

        def spawn_worker(queue_name, processor_class, thread_name, session_pool)
          Thread.new do
            JRuby.reference(Thread.current).native_thread.name = thread_name

            session_pool.consumer(queue_name, filter: @filter) do |session, consumer|
              Tigron.logger.debug "#{self.class.name}: session: #{session.inspect} consumer: #{consumer}"
              Thread.current[:failed] = 0
              Thread.current[:processed] = 0

              loop do
                Thread.current[:status] = :waiting
                raw_message = consumer.receive

                unless raw_message
                  Tigron.logger.info "#{self.class.name}: Empty message!"
                  break
                end

                begin
                  Thread.current[:started_at] = Time.now
                  Thread.current[:status] = :processing
                  Thread.current[:message_id] = raw_message.object_id

                  Tigron.logger.debug inspectable_raw_message(raw_message)

                  encoding = TorqueBox::Messaging::Message.extract_encoding_from_message(raw_message) || TorqueBox::Messaging::Message::DEFAULT_DECODE_ENCODING
                  processor = processor_class.new

                  begin
                    body = if encoding.to_s == 'marshal'
                      Marshal.load(raw_message.body)
                    else
                      klass = TorqueBox::Messaging::Message.class_for_encoding(encoding)
                      message = klass.allocate
                      message.initialize_from_message(OpenStruct.new(text: raw_message.body))
                      message.decode
                    end

                    Tigron.logger.debug "encoding: #{encoding} body: #{body}"

                    processor.process!(TorqueBoxMessageAdapter.new(body))
                  rescue Exception => exception
                    processor.on_error(exception)
                  end

                  raw_message.acknowledge
                  session.commit
                rescue Exception => exception
                  Thread.current[:failed] += 1

                  Tigron.logger.warn "#{self.class.name}: Transaction rollback: #{exception} (#{exception.class.name})"

                  consider_last_message_as_delivered = true
                  session.rollback(consider_last_message_as_delivered)
                  session.commit
                ensure
                  Thread.current[:processed] += 1
                  Thread.current[:started_at] = nil
                  Thread.current[:status] = nil
                  Thread.current[:message_id] = nil
                end
              end

              Tigron.logger.info "#{self.class.name}: Finished thread: #{thread_name}"
            end
          end
        end

        def inspectable_raw_message(raw_message)
          {
            class: raw_message.class.name,
            map: raw_message.to_map,
            # http://www.ruby-doc.org/gems/docs/j/jruby-hornetq-0.4.0/Java/OrgHornetqCoreClientImpl/ClientMessageImpl.html
            # http://hornetq.sourceforge.net/docs/hornetq-2.0.0.BETA5/api/org/hornetq/core/client/impl/ClientMessageImpl.html
            body: raw_message.body.inspect,
            flow_control_size: raw_message.flow_control_size,
            #large_body_size: raw_message.large_body_size,
            is_large_message: raw_message.large_message?,
            address: raw_message.address,
            body_size: raw_message.body_size,
            delivery_count: raw_message.delivery_count,
            is_durable: raw_message.durable?,
            encode_size: raw_message.encode_size,
            is_expired: raw_message.expired?,
            expiration: raw_message.expiration,
            message_id: raw_message.message_id,
            user_id: raw_message.user_id,
            #org.hornetq.core.message.impl.MessageImpl
            #destination: raw_message.getDestination,
            # encode_size: raw_message.encode_size,
            # expiration: raw_message.expiration,
            # message_id: raw_message.message_id,
            priority: raw_message.priority,
            # properties: raw_message.properties,
            # property_names: raw_message.property_names,
            # timestamp: raw_message.timestamp,
            type: raw_message.type,
            # is_durable: raw_message.is_durable,
            # is_expired: raw_message.is_expired
            attributes: raw_message.attributes,
            #properties: raw_message.getProperties,
            is_request: raw_message.request?,
            type_sym: raw_message.type_sym
          }
        end
      end
    end
  end
end

