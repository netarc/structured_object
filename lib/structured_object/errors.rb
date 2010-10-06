class StructuredObject
  module Errors
    class StructuredObjectError < StandardError
      @@used_codes = []

      def self.status_code(code = nil)
        if code
          raise "Status code already in use: #{code}"  if @@used_codes.include?(code)
          @@used_codes << code
        end

        define_method(:status_code) { code }
      end

      def self.error_key(key=nil, namespace=nil)
        define_method(:error_key) { key }
        error_namespace(namespace) if namespace
      end

      def self.error_namespace(namespace)
        define_method(:error_namespace) { namespace }
      end

      def initialize(message=nil, *args)
        message = { :_key => message } if message && !message.is_a?(Hash)
        message = { :_key => error_key, :_namespace => error_namespace }.merge(message || {})
        message = translate_error(message)

        super
      end

      def error_namespace; "structured_object.errors"; end
      def error_key; nil; end

      protected

      def translate_error(opts)
        return nil if !opts[:_key]
        I18n.t("#{opts[:_namespace]}.#{opts[:_key]}", opts)
      end
    end

    class AttributeExists < StructuredObjectError
      status_code(2)
      error_key(:attribute_exists)
    end

    class AttributeInvalid < StructuredObjectError
      status_code(3)
      error_key(:attribute_invalid)
    end

    class ExpectedHash < StructuredObjectError
      status_code(15)
      error_key(:expected_hash)
    end

    class UnknownType < StructuredObjectError
      status_code(50)
      error_key(:unknown_type)
    end
  end
end
