require 'i18n'
require 'byte_buffer'

class StructuredObject
  autoload :Array,   'structured_object/array'
  autoload :Errors,  'structured_object/errors'
  autoload :Struct,  'structured_object/struct'
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

    # This will allow a Proc && Symbol to be matched against ourself for a potential value
    # otherwise simply return the value
    def _resolve_proxy(value)
      value = instance_eval(&value) if value.is_a?(::Proc)
      value = send(value) if value.is_a?(::Symbol)
      value
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
