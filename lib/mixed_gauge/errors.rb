module MixedGauge
  class Error < ::StandardError
  end

  # Raised when try to put new record without distkey attribute.
  class MissingDistkeyAttribute < Error
  end
end
