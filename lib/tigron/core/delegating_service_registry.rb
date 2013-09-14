# encoding: utf-8

module Tigron
  class DelegatingServiceRegistry
    def self.new(*args)
      # http://docs.jboss.org/osgi/jboss-osgi-1.0.0/apidocs/org/jboss/msc/service/DelegatingServiceRegistry.html
      org.jboss.msc.service.DelegatingServiceRegistry.new(*args)
    end
  end
end

