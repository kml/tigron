# encoding: utf-8

module HornetQ
  module Client
    class Connection
      def create_transacted_session(params = {})
        raise "HornetQ::Client::Connection Already Closed" unless @connection
        session = @connection.create_transacted_session
        (@sessions << session) if params.fetch(:managed, false)
        session
      end
    end
  end
end

require 'hornetq/client/org_hornetq_api_core_client_client_session'

module Java::org.hornetq.api.core.client::ClientSession
  # Create a queue if it doesn't already exist
  def create_queue_ignore_exists(address, queue, durable)
    begin
      create_queue(address, queue, durable)
    # http://docs.jboss.org/hornetq/2.2.5.Final/api/org/hornetq/api/core/HornetQException.html
    rescue Java::org.hornetq.api.core.HornetQException => exception
      code = exception.respond_to?(:code) ? exception.code : exception.cause.code
      raise if code != Java::org.hornetq.api.core.HornetQException::QUEUE_EXISTS
    end
  end
end

require 'hornetq/client/org_hornetq_core_client_impl_client_message_impl'

class Java::OrgHornetqCoreClientImpl::ClientMessageImpl
  #NameError: undefined local variable or method `properties' for #<Java::OrgHornetqCoreClientImpl::ClientMessageImpl:0x5fe6d7b6>
  #  getProperties at /Users/.../jruby-hornetq/lib/hornetq/client/org_hornetq_core_client_impl_client_message_impl.rb:338
  #        inspect at /Users/.../jruby-hornetq/lib/hornetq/client/org_hornetq_core_client_impl_client_message_impl.rb:372
  # Does not include the body since it can only read once
  def inspect
    "#{self.class.name}:\nBody: #{body.inspect}\nAttributes: #{attributes.inspect}"#\nProperties: #{getProperties.inspect}"
  end
end

