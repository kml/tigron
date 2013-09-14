# encoding: utf-8

require 'gene_pool'
require 'hornetq/client'

module HornetQ::Client
  class TransactedSessionPool
    def initialize(connection, params={})
      session_params = (params || {}).dup
      pool_options = {
        name: session_params[:pool_name] || self.class.name,
        pool_size: session_params[:pool_size] || 10,
        warn_timeout: session_params[:pool_warn_timeout] || 5,
        logger: session_params[:pool_logger],
      }

      @pool = GenePool.new(pool_options) do
        session = connection.create_transacted_session
        session.start
        session
      end
    end

    def session(&block)
      @pool.with_connection(&block)
    end

    def consumer(queue_name, options = {}, &block)
      session do |s|
        consumer = nil
        begin
          consumer = s.create_consumer(queue_name, options[:filter].to_s)
          block.call(s, consumer)
        ensure
          consumer.close if consumer
        end
      end
    end

    def close
      @pool.each do |s|
        s.close
      end
    end
  end
end

