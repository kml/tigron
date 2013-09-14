# encoding: utf-8

# Puma as default rails server
require 'rack/handler'
require 'puma'
Rack::Handler::WEBrick = Rack::Handler.get(:puma)

