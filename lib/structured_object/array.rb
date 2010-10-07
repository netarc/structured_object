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
      @options = @format[2]

      @size = @options[:size] || nil
      unless @size.nil?
        @size = @instance._resolve_proxy(@size)

        raise StandardError.new("An array size must be specified in Numeric format") unless @size.is_a?(::Numeric)
        raise StandardError.new("An array cannot have a size less than 1") if @size < 1
        @size = @size.floor
      end

      @length = @options[:length] || nil
      unless @length.nil?
        @length = @instance._resolve_proxy(@length)

        raise StandardError.new("An array length must be specified in Numeric format") unless @length.is_a?(::Numeric)
        raise StandardError.new("An array cannot ave a size less than 0") if @length < 0
        @length = @length.floor
      end

      @data = []
      if @type == :type
        @type_klass = StructuredObject::Value
      elsif @type == :struct
        @type_klass = @format[1]
      end

      unless @size.nil?
        @size.times.each do
          @data << self.new
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


    def size
      to_a.size
    end
    alias :length :size

    def each
      to_a.each do |x|
        yield x
      end
    end

    def to_a
      @data
    end
    alias :entries :to_a

    def [](index)
      result = to_a[index]
      result = result.value if result.respond_to?(:value)
      result
    end

    def []=(index, item)
      raise StandardError.new("unsupported") unless @type == :type
      to_a[index].value = item
    end

    # Remove last element in array
    #  - in a fixed array size, the element being removed is replaced with a fresh/default instance
    def pop
      res = @data.pop
      @data.push self.new unless @size.nil?
      res
    end

    # Remove first element in array
    #  - in a fixed array size, the element being removed is replaced with a fresh/default instance
    def shift
      res = @data.shift
      @data.unshift self.new unless @size.nil?
      res
    end

    # Add specified item to front of array
    #  - in a fixed array size, the element at the end is bumped off
    def unshift(item)
      item = _enforce!(item)
      @data.pop unless @size.nil?
      @data.unshift(item)
      self
    end

    # Add specified item to end of array
    #  - in a fixed array size, the element at the front is bumped off
    def push(item)
      item = _enforce!(item)
      @data.shift unless @size.nil?
      @data.push item
      self
    end
    alias :<< :push

    def inspect
      "<StructuredObject::Array:0x#{'%x' % (self.object_id << 1)} #{to_a.inspect}>"
    end
  end
end
