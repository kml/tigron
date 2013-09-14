# encoding: utf-8

module Tigron
  class Engine < ::Rails::Engine
    isolate_namespace Tigron

    initializer 'tigron' do
      Tigron.initialize!
    end
  end
end

