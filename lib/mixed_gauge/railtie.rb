module MixedGauge
  # Railtie of mixed_gauge
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.expand_path('../../tasks/mixed_gauge.rake', __FILE__)
    end
  end
end
