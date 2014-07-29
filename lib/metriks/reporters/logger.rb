require 'metriks/time_tracker'
require 'logger'

module Metriks::Reporters
  class Logger < Metriks::Reporter
    attr_accessor :prefix, :log_level, :logger

    def initialize(options = {})
      options[:prefix] ||= 'metriks:'

      super(options)

      @logger    = options[:logger]    || ::Logger.new(STDOUT)
      @log_level = options[:log_level] || ::Logger::INFO
    end

    def write
      @registry.each do |name, metric|
        case metric
        when Metriks::Meter
          log_metric name, 'meter', metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate
          ]
        when Metriks::Counter
          log_metric name, 'counter', metric, [
            :count
          ]
        when Metriks::Gauge
          log_metric name, 'gauge', metric, [
            :value
          ]
        when Metriks::UtilizationTimer
          log_metric name, 'utilization_timer', metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev,
            :one_minute_utilization, :five_minute_utilization,
            :fifteen_minute_utilization, :mean_utilization,
          ], [
            :median, :get_95th_percentile
          ]
        when Metriks::Timer
          log_metric name, 'timer', metric, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
        when Metriks::Histogram
          log_metric name, 'histogram', metric, [
            :count, :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
        end
      end
    end

    def extract_from_metric(metric, *keys)
      keys.flatten.collect do |key|
        name = key.to_s.gsub(/^get_/, '')
        [ { name => metric.send(key) } ]
      end
    end

    def log_metric(name, type, metric, keys, snapshot_keys = [])
      message = []

      message << @prefix if @prefix
      message << { :time => Time.now.to_i }

      message << { :name => name }
      message << { :type => type }
      message += extract_from_metric(metric, keys)

      unless snapshot_keys.empty?
        snapshot = metric.snapshot
        message += extract_from_metric(snapshot, snapshot_keys)
      end

      @logger.add(@log_level, format_message(message))
    end

    def format_message(args)
      args.map do |arg|
        case arg
        when Hash then arg.map { |name, value| "#{name}=#{format_message([value])}" }
        when Array then format_message(arg)
        else arg
        end
      end.join(' ')
    end
  end
end
