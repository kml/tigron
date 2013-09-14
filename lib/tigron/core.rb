# encoding: utf-8

require 'java'
require 'jruby'
require 'jruby/core_ext'

Dir[File.join(File.expand_path('../../../vendor', __FILE__), '*.jar')].each do |jar|
  require jar
end

require 'jruby-hornetq'

require 'torquebox-core'
require 'tigron/core/delegating_service_registry'
require 'tigron/core/deployment_unit'
require 'tigron/core/service_container'

require 'torquebox/service'

require 'tigron/core/torquebox/core/util/string_utils'
require 'tigron/core/torquebox/jobs/scheduled_job'
require 'tigron/core/torquebox/services/ruby_service'
require 'tigron/core/service_proxy'
require 'tigron/core/service_value'
require 'tigron/core/bootstrap'
require 'tigron/core/configuration'

