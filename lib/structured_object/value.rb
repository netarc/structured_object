class StructuredObject
  # Value is a type enforced value container
  class Value
    def initialize(instance, format=[])
      @instance = instance
      @format = format

      type_name = @format[1]
      options = @format[2] || {}

      @options = {
        :value => options[:value] || nil
      }

      @read_type_key = :"read_#{type_name}"
      @write_type_key = :"write_#{type_name}"

      default_value = StructuredObject::Tools.resolve_proxy(@instance, options[:default] || 0)

      @buffer_opts = {}
      @buffer_opts[:endian] = options[:endian] if [:big_endian, :little_endian].include?(options[:endian])

      @buffer = ByteBuffer.new
      @buffer.send(@write_type_key, default_value, @buffer_opts)
    end

    def value
      @buffer.rewind!
      @buffer.send(@read_type_key, @buffer_opts)
    end

    def value= v
      @buffer.reset!
      @buffer.send(@write_type_key, v, @buffer_opts)
    end

    def serialize_struct(buffer)
      unless @options[:value].nil?
        self.value = StructuredObject::Tools.resolve_proxy(@instance, @options[:value])
      end
      @buffer.rewind!
      buffer.send(@write_type_key, @buffer.send(@read_type_key, @buffer_opts), @buffer_opts)
    end

    def unserialize_struct(buffer)
      @buffer.reset!
      @buffer.send(@write_type_key, buffer.send(@read_type_key, @buffer_opts), @buffer_opts)
    end

    def inspect
      value
    end
  end
end
