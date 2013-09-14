# encoding: utf-8

require 'tigron/web/puma/monitoring'

module Tigron
  module Web
    module Puma
      class Service
        def start(start_context)
        end

        def stop(stop_context)
        end

        def value
          Tigron::Web::Puma::Monitoring.new.all
        end
      end
    end
  end
end

