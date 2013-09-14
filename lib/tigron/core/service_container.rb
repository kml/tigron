# encoding: utf-8

module Tigron
  class ServiceContainer
    def self.new
      # http://docs.jboss.org/osgi/jboss-osgi-1.0.0/apidocs/org/jboss/msc/service/ServiceContainer.Factory.html
      org.jboss.msc.service.ServiceContainerImpl::Factory.create
    end
  end
end

