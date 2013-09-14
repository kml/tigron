# encoding: utf-8

module Tigron
  # implements Java::OrgJbossMscService::Service
  class ServiceValue

    def initialize(value)
      @value = value
    end

    def start(start_context)
    end

    def stop(stop_context)
    end

    def value
      @value
    end
  end
end

