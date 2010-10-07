class StructuredObject
  module Tools
    class << self
      def assert_valid_keys(hash, *valid_keys)
        unknown_keys = hash.keys - [valid_keys].flatten
        raise Errors::ArgumentError.new(:keys => unknown_keys.join(", ")) unless unknown_keys.empty?
      end
    end
  end
end
