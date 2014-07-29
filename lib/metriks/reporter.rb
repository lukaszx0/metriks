require 'metriks/time_tracker'

class Metriks::Reporter
  def initialize(options = {})
    @prefix = options[:prefix]

    @registry  = options[:registry] || Metriks::Registry.default
    @time_tracker = Metriks::TimeTracker.new(options[:interval] || 60)
    @on_error  = options[:on_error] || proc { |ex| }
  end

  def start
    @thread ||= Thread.new do
      loop do
        @time_tracker.sleep
        flush
      end
    end
  end

  def stop
    @thread.kill if @thread
    @thread = nil
  end

  def restart
    start
    stop
  end

  def flush
    Thread.new do
      begin
        write
      rescue Exception => ex
        @on_error[ex] rescue nil
      end
    end
  end

  def write
    raise NotImplementedError
  end
end
