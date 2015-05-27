module MixedGauge
  class Error < ::StandardError
  end

  # Raised when try to put new record without distkey attribute.
  class MissingDistkeyAttribute < Error
  end

  # Inherit from AR::RecordNotFound to enable to handle as AR's one.
  class RecordNotFound < ActiveRecord::RecordNotFound
  end
end
