# encoding: utf-8

require 'active_support/core_ext/string/inflections'

# NameError: missing class or uppercase package name (`org.torquebox.core.util.StringUtils')
# from org/jruby/javasupport/JavaUtilities.java:54:in `get_proxy_or_package_under_package'

module TorqueBox
  module Core
    module Util
      module StringUtils
        def underscore(name)
          name.underscore
        end

        module_function :underscore
      end
    end
  end
end

JavaUtilities.class_eval do
  class << self
    alias_method :get_proxy_or_package_under_package_original, :get_proxy_or_package_under_package
    def get_proxy_or_package_under_package(obj, sym)
      sym == :StringUtils ? TorqueBox::Core::Util::StringUtils : get_proxy_or_package_under_package_original(obj, sym)
    end
  end
end

