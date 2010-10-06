class StructuredObject
  # Array is a type enforcement for an array of data
  class Array
    include Enumerable

    def initialize(instance, format=[])
      puts "Creating Array with format: #{format.inspect}"
      @format = format
      @instance = instance

      @type = @format[0]
      @type_klass = nil

      @type_name = @format[1]
      options = @format[2]

      @size = options[:size] || nil
      unless @size.nil?
        @size = @instance._resolve_proxy(@size)

        raise StandardError.new("An array size must be specified in Numeric format") unless @size.is_a?(::Numeric)
        raise StandardError.new("An array cannot have a size less than 1") if @size < 1
        @size = @size.floor
      end

      @length = options[:length] || nil
      unless @length.nil?
        @length = @instance._resolve_proxy(@length)

        raise StandardError.new("An array length must be specified in Numeric format") unless @length.is_a?(::Numeric)
        raise StandardError.new("An array length have a size less than 1") if @length < 1
        @length = @length.floor
      end

      @data = []
      if @type == :type
        # TODO: Rethink this? maybe use StructuredObject::Value somehow?
        @read_type_key = :"read_#{@type_name}"
        @write_type_key = :"write_#{@type_name}"

        @buffer = ::ByteBuffer.new

        unless @size.nil?
          @size.times.each do
            @buffer.send(@write_type_key, 0)
          end
          @buffer.rewind!
          @size.times.each do
            @data << @buffer.send(@read_type_key)
          end
        end
      elsif @type == :struct
        @type_klass = @type_name

#        puts " - creating instances of #{@type_klass}"
        unless @size.nil?
          @size.times.each do
            @data << self.new
          end
        end
#        puts " - end"
      end
    end

    # Return a new instance of our Struct object
    def new
      raise StandardError.new("No valid struct is present, unable to create new instance") if @type_klass.nil?
      instance = @type_klass.new
      instance.send :initialize_structured_object
      instance
    end

    def _type_item(item)
      raise StandardError.new("Unexpected item of #{item.class}, Expecting item of struct #{@type_klass}") if !@type_klass.nil? && !item.is_a?(@type_klass)
    end
    private :_type_item


    def each
      to_a.each do |x|
        yield x
      end
    end

    def to_a
      @data
    end
    alias :entries :to_a

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
      _type_item(item)
      @data.pop unless @size.nil?
      @data.unshift(item)
      self
    end

    # Add specified item to end of array
    #  - in a fixed array size, the element at the front is bumped off
    def push(item)
      _type_item(item)
      @data.shift unless @size.nil?
      @data.push item
      self
    end
    alias :< :push

    def inspect
      "<StructuredObject::Array:0x#{'%x' % (self.object_id << 1)} #{to_a.inspect}>"
    end
  end
end
