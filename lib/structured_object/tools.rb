class StructuredObject
  class Tools
    class << self
      def assert_valid_keys(hash, *valid_keys)
        unknown_keys = hash.keys - [valid_keys].flatten
        raise Errors::ArgumentError.new(:keys => unknown_keys.join(", ")) unless unknown_keys.empty?
      end

      # This will allow a Proc && Symbol to be matched against an object for a potential value otherwise simply return the value
      def resolve_proxy(object, value)
        value = object.instance_eval(&value) if value.is_a?(::Proc)
        value = object.send(value) if value.is_a?(::Symbol)
        value
      end
    end
  end
end
