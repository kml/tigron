# encoding: utf-8

module Tigron
  # implements Java::OrgJbossMscService::Service
  class ServiceProxy
    def initialize(name, properties)
      @name = name
      @properties = properties
      @service = build_service
      @started = false
    end

    def start(start_context)
      @service.start
      @started = true
    end

    def stop(stop_context)
      @service.stop
      @started = false
    end

    def name
      @name
    end

    def service
      @service
    end

    def started?
      @started
    end

    def value
      TorqueBox::Services::RubyService.new(self)
    end

    private

    def build_service
      if @properties.has_key?(:config)
        return @properties[:service].new(@properties[:config])
      end

      @properties[:service].new
    end
  end
end

