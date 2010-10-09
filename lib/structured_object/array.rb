class StructuredObject
  # Array is a type enforcement for an array of data
  class Array
    include Enumerable

    def initialize(instance, format=[])
      puts "Creating Array with format: #{format.inspect}"
      @format = format
      @instance = instance
      @type_klass = nil
      @type = @format[0]
      @data = []
      options = @format[2]

      @options = {
        :size => StructuredObject::Tools.resolve_proxy(@instance, options[:size] || nil),
        :length => StructuredObject::Tools.resolve_proxy(@instance, options[:length] || nil)
      }

      unless @options[:size].nil?
        raise StandardError.new("An array size must be specified in Numeric format") unless @options[:size].is_a?(::Numeric)
        raise StandardError.new("An array cannot have a size less than 1") if @options[:size] < 1
        @options[:size] = @options[:size].floor
      end

      unless @options[:length].nil?
        raise StandardError.new("An array length must be specified in Numeric format") unless @options[:length].is_a?(::Numeric)
        raise StandardError.new("An array cannot ave a size less than 0") if @options[:length] < 0
        @options[:length] = @options[:length].floor
      end

      if @type == :type
        @type_klass = StructuredObject::Value
      elsif @type == :struct
        @type_klass = @format[1]
      end

      unless @options[:size].nil?
        if @type == :type
          value_helper = self.new
          @options[:size].times.each do
            @data << value_helper.value
          end
        elsif @type == :struct
          @options[:size].times.each do
            @data << self.new
          end
        end
      end
    end

    # Return a new instance of our Struct new
    def new
      raise StandardError.new("No valid struct is present, unable to create new instance") if @type_klass.nil?
      instance = nil
      if @type == :type
        instance = @type_klass.new(@instance, @format)
      elsif @type == :struct
        instance = @type_klass.new
        instance.send :initialize_structured_object
      end
      instance
    end

    def _enforce!(item)
      if @type == :type
        unless item.is_a?(@type_klass)
          item = self.new.tap {|i| i.value = item}
        end
      else
        raise StandardError.new("Unexpected item of #{item.class}, Expecting item of struct #{@type_klass}") if !item.is_a?(@type_klass)
      end
      item
    end
    private :_enforce!

    def _valueize!(result)
      if result.is_a?(::Array)
        result = result.collect {|n| n.respond_to?(:value) ? n.value : n}
      else
        result = result.value if result.respond_to?(:value)
      end
      result
    end
    private :_valueize!

    # required for Enumerable
    def each
      to_a.each {|x| yield x}
    end

    def to_a
      new_data = []
      if @type == :type
        value_helper = self.new

        @data.each do |element|
          value_helper.value = element
          new_data << value_helper.value
        end
      else
#       raise StandardError.new("unsupported") unless @type == :type
      end
      @data = new_data
      @data
    end

    # Helper to reduce the bulk of forwarded methods
    def self.forwarded_method(method)
      if method.is_a?(::Array)
        method.each {|m| forwarded_method(m) }
        return
      end
      define_method(method) {|*args| to_a.send(method, *args)}
    end

    # Forward Array methods
    forwarded_method([:[], :[]=, :<<, :==,:at, :choice, :fetch, :first, :include?, :index, :join, :last,
                      :length, :pop, :push, :reject, :reverse, :rindex, :shift, :shuffle, :size, :slice,
                      :take, :uniq, :unshift, :values_at])

    def inspect
      if @type == :type
        "<StructuredObject::Array:0x#{'%x' % (self.object_id << 1)} #{@format[1]}::#{to_a.inspect}>"
      else
        "<StructuredObject::Array:0x#{'%x' % (self.object_id << 1)} #{to_a.inspect}>"
      end
    end
  end
end
