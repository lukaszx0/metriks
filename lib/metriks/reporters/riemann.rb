require 'metriks/reporter'

module Metriks::Reporters
  class Riemann < Metriks::Reporter
    require 'riemann/client'

    attr_accessor :client

    def initialize(options = {})
      super(options)

      @client = ::Riemann::Client.new(
        :host => options[:host],
        :port => options[:port]
      )

      @default_event = options[:default_event] || {}
      @default_event[:ttl] ||= ((options[:interval] || 60) * 1.5)
    end

    def write
      @registry.each do |name, metric|
        case metric
        when Metriks::Meter
          send_metric name, 'meter', metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate
          ]
        when Metriks::Counter
          send_metric name, 'counter', metric, [
            :count
          ]
        when Metriks::Gauge
          send_metric name, 'gauge', metric, [
            :value
          ]
        when Metriks::UtilizationTimer
          send_metric name, 'utilization_timer', metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev,
            :one_minute_utilization, :five_minute_utilization,
            :fifteen_minute_utilization, :mean_utilization,
          ], [
            :median, :get_95th_percentile
          ]
        when Metriks::Timer
          send_metric name, 'timer', metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
        when Metriks::Histogram
          send_metric name, 'histogram', metric, [
            :count, :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
        end
      end
    end

    def send_metric(name, type, metric, keys, snapshot_keys = [])
      keys.each do |key|
        @client << @default_event.merge(
          :service => "#{name} #{key}",
          :metric => metric.send(key),
          :tags => [type]
        )
      end

      unless snapshot_keys.empty?
        snapshot = metric.snapshot
        snapshot_keys.each do |key|
          @client << @default_event.merge(
            :service => "#{name} #{key}",
            :metric => snapshot.send(key),
            :tags => [type]
          )
        end
      end
    end
  end
end
