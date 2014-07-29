require 'metriks/reporter'

module Metriks::Reporters
  class ProcTitle < Metriks::Reporter
    def initialize(options = {})
      options[:prefix]   ||= $0.dup
      options[:interval] ||= 5

      super(options)

      @rounding = options[:rounding] || 1
      @metrics  = []
    end

    def add(name, suffix = nil, &block)
      @metrics << [ name, suffix, block ]
    end

    def empty?
      @metrics.empty?
    end

    def write
      unless @metrics.empty?
        title = generate_title
        if title && !title.empty?
          $0 = "#{@prefix} #{title}"
        end
      end
    end

    protected

    def generate_title
      @metrics.collect do |name, suffix, block|
        val = block.call
        val = "%.#{@rounding}f" % val if val.is_a?(Float)

        "#{name}: #{val}#{suffix}"
      end.join(' ')
    end
  end
end
