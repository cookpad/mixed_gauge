require "mixed_gauge/version"

module MixedGauge
  class << self
    def config
      @config ||= Config.new
    end

    def configure(&block)
      config.instance_eval(&block)
    end
  end
end
