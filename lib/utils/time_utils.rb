module Utils
  module TimeUtils
    def self.parse_iso8601(value, default: Time.current)
      return default if value.blank?
      Time.iso8601(value.to_s)
    rescue ArgumentError
      default
    end
  end
end

