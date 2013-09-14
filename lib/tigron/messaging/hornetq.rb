# encoding: utf-8

require 'jruby-hornetq'

require 'torquebox-messaging'
require 'torquebox/messaging/connection_factory'
require 'torquebox/messaging/xa_connection_factory'
require 'torquebox/messaging/backgroundable_processor'

module Tigron
  module Messaging
    module HornetQ
    end
  end
end

require 'tigron/messaging/hornetq/ext/hornetq/client/transacted_session_pool'
require 'tigron/messaging/hornetq/ext/hornetq'
require 'tigron/messaging/hornetq/monitoring'
require 'tigron/messaging/hornetq/server_service'
require 'tigron/messaging/hornetq/service'
require 'tigron/messaging/hornetq/torquebox_message_adapter'
require 'tigron/messaging/hornetq/worker_pool'

