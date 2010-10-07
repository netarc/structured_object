class StructuredObject
  # Struct is our DSL object for StructuredObject
  class Struct
    def initialize(klass, format={})
      @klass = klass
      @struct_format = format
      @current_block = @struct_format
    end

    @@valid_keys_for_struct = [:size, :length, :endian]
    def struct(attribute, *args, &block)
      options = args.last.is_a?(::Hash) ? args.pop : {}
      Tools.assert_valid_keys(options, @@valid_keys_for_struct)

      if block_given?
        klass = Class.new(StructuredObject)
        @klass.const_set("Struct#{attribute.to_s.capitalize}", klass)
        klass.structured_format.instance_eval &block
      else
        klass = args.pop
        klass = klass.call if klass.is_a?(::Proc)
        raise Errors::StructExpectedClass.new if klass.nil?
      end

      @current_block.merge!({attribute => [:struct, klass, options]})

      @klass.send(:define_method, attribute) do
        initialize_structured_object
        @structured_object[:"#{attribute}"]
      end
    end

    @@valid_keys_for_type = [:default, :size, :length, :endian]
    def type(attribute, type, options={})
      Tools.assert_valid_keys(options, @@valid_keys_for_type)

      # We accept attribute as an Array for a shortcut to declaring multiple types of the same type
      if attribute.is_a?(::Array)
        attribute.each {|_type_id| type(_type_id, type, options) }
        return
      end

      raise Errors::AttributeInvalid.new(:type => type,:klass => attribute.class) unless attribute.is_a?(::Symbol)
      raise Errors::AttributeExists.new(:attribute => attribute, :klass => @klass) if @current_block.has_key?(attribute)
      raise Errors::UnknownType.new(:type => type) unless ByteBuffer.known_types.include?(type)

      @current_block.merge!({attribute => [:type, type, options]})

      @klass.send(:define_method, attribute) do
        initialize_structured_object
        result = @structured_object[:"#{attribute}"]
        result = result.value if result.respond_to?(:value)
        result
      end

      @klass.send(:define_method, :"#{attribute}=") do |value|
        initialize_structured_object
        @structured_object[:"#{attribute}"].value = value
      end
    end

    # method_missing is assuming we are trying to mean a type. (IE byte, char, int8, etc..)
    def method_missing(*args)
      options = args.last.is_a?(::Hash) ? args.pop : {}
      attribute = args[1]
      type = args[0]

      type(attribute, type, options)
    end
  end
end
