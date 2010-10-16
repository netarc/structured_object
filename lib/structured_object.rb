require 'i18n'
require 'byte_buffer'

class StructuredObject
  autoload :Array,   'structured_object/array'
  autoload :Errors,  'structured_object/errors'
  autoload :Struct,  'structured_object/struct'
  autoload :Tools,   'structured_object/tools'
  autoload :Value,   'structured_object/value'

  module Base
    def self.included(base)
      base.extend ClassMethods
    end

    @structured_object = nil
    def initialize_structured_object
      return if @structured_object
      @structured_object= {}

      struct_format = self.class.structured_format.instance_variable_get(:@struct_format)
      struct_format.each_pair do |key, v|
        type = v[0]
        options = v[2]

        # Are we an array?
        unless (options[:length] || options[:size]).nil?
          @structured_object[key] = StructuredObject::Array.new(self, v)
        else
          if type == :type
            @structured_object[key] = StructuredObject::Value.new(self, v)
          elsif type == :struct
            o = klass = v[1].new
            @structured_object[key] = o
          end
        end
      end
    end

    def inspect
      return super if @structured_object.nil?

      key_values = @structured_object.keys.map do |key|
        value = send(key)
        [key, value.inspect]
      end
      "#<#{self.class}:0x#{'%x' % (self.object_id << 1)} #{key_values.map{|e| e.join('=')}.join(' ')}>"
    end

    def serialize_struct
      data = ""
      initialize_structured_object
      keys = self.class.structured_format.instance_variable_get(:@keys)
      keys.each do |key|
        data += @structured_object[key].serialize_struct
      end
      data
    end

    def unserialize_struct(data)
      if data.is_a?(::String)
        buffer = ByteBuffer.new(data)
      elsif data.is_a?(::ByteBuffer)
        buffer = data
      else
        raise "Invalid data"
      end

      initialize_structured_object
      keys = self.class.structured_format.instance_variable_get(:@keys)
      keys.each do |key|
        @structured_object[key].unserialize_struct(buffer)
      end
    end

    module ClassMethods
      @@structured_formats = Hash.new { |hash, key| hash[key] = Struct.new(key) }
      def structured_format
        @@structured_formats[self]
      end

      def has_structured_format?
        @@structured_formats.has_key?(self)
      end

      # Entry to the DSL
      def struct(*args, &block)
        structured_format.instance_eval &block
      end
    end
  end

  include Base

  class << self
    # The source root is the path to the root directory of the StructuredObject gem.
    def source_root
      @@source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end
end

# Default I18n to load the en locale
I18n.load_path << File.expand_path("../../templates/locales/en.yml", __FILE__)

require 'structured_object/version'


class ByteBuffer
  define_type :vuint do |type|
    type.read = Proc.new do |byte_buffer, args|
      shift = 0
      value = 0
      while true
        byte = byte_buffer.read_byte.to_i
        if byte & 0x80 == 0
          value |= (byte << shift)
          break
        else
          value |= ((byte & 0x7F) << shift)
        end
        shift += 7
      end
      value
#       :read => Proc.new {
#         byte = read_byte_val
#         shift = 0
#         value = 0
#         while not byte.nil?
#           if byte & 0x80 == 0
#             value |= (byte << shift)
#             break
#             # return value | (byte << shift)
#           else
#             value = value | ((byte & 0x7F) << shift)
#           end
#           shift += 7
#           byte = read_byte_val
#         end
#         value
#       },
    end
    type.write = Proc.new do |byte_buffer, data|
      value = data.to_i
      bits = (Math.log(value.abs)/Math.log(2)).floor + 1
      shift = 0
      while bits > 0
        vv = (value >> shift) & 0x7F
        vv |= 0x80 if (bits > 7)
        byte_buffer.write_byte vv
        shift+= 7
        bits -= 7
      end
#       :write => Proc.new {  v = value.to_i
#         bits = v.ubits
#         shift = 0
#         while bits > 0
#           vv = (v >> shift) & 0x7F
#           vv |= 0x80 if (bits > 7)
#           write vv
#           shift += 7
#           bits -= 7
#         end
#         byte_buffer.write data.is_a?(String) ? data[0..3] : [data.to_i].pack('L')
    end
  end
end
