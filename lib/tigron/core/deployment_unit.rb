# encoding: utf-8

module Tigron
  class DeploymentUnit
    def self.new(*args)
      # http://tigronoverflow.com/questions/4888798/jruby-no-public-constructor
      constructor = org.jboss.as.server.deployment.DeploymentUnitImpl.java_class.declared_constructors.first
      constructor.accessible = true
      constructor.new_instance(*args).to_java
    end
  end
end

