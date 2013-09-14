# encoding: utf-8

require 'puma'
require 'uri'

module Tigron
  module Web
    module Puma
      class Monitoring
        def all
          puma = options.except(:on_restart, :worker_boot)

          puma[:on_restart_count] = options[:on_restart].count
          puma[:worker_boot_count] = options[:worker_boot].count

          puma[:min_threads] = Integer(options[:min_threads])
          puma[:max_threads] = Integer(options[:max_threads])

          puma[:cluster] = options[:workers] > 0

          puma[:actions] = {
            stats: puma_control_action_url('stats'),
            stop: puma_control_action_url('stop'),
            halt: puma_control_action_url('halt'),
            restart: puma_control_action_url('restart'),
            :'phased-restart' => puma_control_action_url('phased-restart')
          }

          puma
        end

        def puma_control_action_url(action)
          return unless options[:control_url]

          uri = URI.parse(options[:control_url])

          token = options[:control_auth_token]
          host = uri.host
          port = uri.port

          "http://#{host}:#{port}/#{action}?token=#{token}"
        end

        def options
          ::Puma.cli_config.options
        end
      end
    end
  end
end

