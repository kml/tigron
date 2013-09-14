# encoding: utf-8

module Tigron
  module Messaging
    module HornetQ
      class TorqueBoxMessageAdapter
        def initialize(message)
          @message = message
        end

        def decode
          @message
        end
      end
    end
  end
end

