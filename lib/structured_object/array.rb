class StructuredObject
  # Array is a type enforcement for an array of data
  class Array
    include Enumerable

    @@valid_keys_for_array = [:fixed_size, :initial_size, :storage]
    def initialize(instance, format=[])
      @format = format
      @instance = instance
      @type_klass = nil
      @type = @format[0]
      @data = []
      options = @format[2]

      array_options = options[:array].is_a?(::Hash) ? options[:array] : {}
      Tools.assert_valid_keys(array_options, @@valid_keys_for_array)
      @options = {
        :fixed_size => StructuredObject::Tools.resolve_proxy(@instance, array_options[:fixed_size] || nil),
        :initial_size => array_options[:initial_size] || nil,
        :storage => StructuredObject::Tools.resolve_proxy(@instance, array_options[:storage].nil? ? nil : array_options[:storage])
      }

      unless @options[:fixed_size].nil?
        raise StandardError.new("An array size must be specified in Numeric format") unless @options[:fixed_size].is_a?(::Numeric)
        raise StandardError.new("An array cannot have a fixed size less than 1") if @options[:fixed_size] < 1
        @options[:fixed_size] = @options[:fixed_size].floor
      end

      unless @options[:initial_size].nil? || @options[:initial_size].is_a?(::Proc)
        raise StandardError.new("An array size must be specified in Numeric format") unless @options[:initial_size].is_a?(::Numeric)
        raise StandardError.new("An array cannot have a initial size less than 0") if @options[:initial_size] < 0
        @options[:initial_size] = @options[:initial_size].floor
      end

      if @type == :type
        @type_klass = StructuredObject::Value
      elsif @type == :struct
        @type_klass = @format[1]
      end

      unless @options[:fixed_size].nil?
        if @type == :type
          value_helper = self.new
          @options[:fixed_size].times.each do
            @data << value_helper.value
          end
        elsif @type == :struct
          @options[:fixed_size].times.each do
            @data << self.new
          end
        end
      end
    end

    def serialize_struct(buffer)
      items = to_a

      if @options[:fixed_size].nil?
        if @options[:storage].nil?
          buffer.write_vuint items.size
        elsif @options[:storage] == false
        else
          buffer.send(:"write_#{@options[:storage].to_s}", items.size)
        end
      end

      if @type == :type
        value_helper = self.new
        items.each do |item|
          value_helper.value = item
          value_helper.serialize_struct(buffer)
        end
      elsif @type == :struct
        items.each do |item|
          item.serialize_struct(buffer)
        end
      end
    end

    def unserialize_struct(buffer)
      if @options[:fixed_size].nil?
        if !@options[:initial_size].nil?
          count = StructuredObject::Tools.resolve_proxy(@instance, @options[:initial_size])
        elsif @options[:storage].nil?
          count = buffer.read_vuint
        elsif @options[:storage] == false
          count = 0
        else
          count = buffer.send(:"read_#{@options[:storage].to_s}")
        end
      else
        count = @options[:fixed_size]
      end
      items = []
      if @type == :type
        value_helper = self.new
        count.times.each do
          value_helper.unserialize_struct(buffer)
          items << value_helper.value
        end
      elsif @type == :struct
        count.times.each do
          item = self.new
          item.unserialize_struct(buffer)
          items << item
        end
      end
      @data = items
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

    # Set our array to new values
    def value=(new_value)
      @data = new_value
    end

    # Enforce the size constraints on the array
    def _enforce_size!(position=:else)
      if @type == :type
        unless @options[:fixed_size].nil?
          # Ensure we are at min size
          value_helper = self.new
          while @data.size < @options[:fixed_size]
            @data << value_helper.value
          end
          # Ensure we are at miax size
          while @data.size > @options[:fixed_size]
            if position == :start
              @data.shift
            else
              @data.pop
            end
          end
        end
      elsif @type == :struct
        unless @options[:fixed_size].nil?
          # Ensure we are at min size
          while @data.size < @options[:fixed_size]
            @data << self.new
          end
          # Ensure we are at miax size
          while @data.size > @options[:fixed_size]
            if position == :start
              @data.shift
            else
              @data.pop
            end
          end
        end
      end
    end
    private :_enforce_size!

    # required for Enumerable
    def each
      to_a.each {|x| yield x}
    end

    # Return our data array, this will enforce our array to its type
    def to_a
      new_data = []

      if @type == :type
        value_helper = self.new

        @data.each do |element|
          value_helper.value = element
          new_data << value_helper.value
        end

        @data = new_data
      elsif @type == :struct
        @data.each do |element|
          new_data << element if element.is_a?(@type_klass)
        end
        @data = new_data
      end
      _enforce_size!
      @data
    end

    # Helper to reduce the bulk of forwarded methods
    def self.forward_read_method(method)
      if method.is_a?(::Array)
        method.each {|m| forward_read_method(m) }
        return
      end
      define_method(method) do |*args|
        result = to_a.send(method, *args)
      end
    end

    # Helper to reduce the bulk of forwarded methods that need to be enforced
    def self.forward_write_method(munge)
      munge.each_pair do |key, methods|
        methods.each do |method|
          define_method(method) do |*args|
            result = @data.send(method, *args)
            _enforce_size!(key)
            result
          end
        end
      end
    end

    # Forward Array read methods
    forward_read_method([:[], :==,:at, :choice, :fetch, :first, :include?, :index, :join, :last,
                      :length, :reject, :reverse, :rindex, :shuffle, :size, :slice,
                      :take, :uniq, :values_at])

    # Forward Array write methods, these access our raw array
    forward_write_method({:start => [:[]=, :<<], :else => [:pop, :push, :shift, :slice!, :unshift]})

    def inspect
      if @type == :type
        "<StructuredObject::Array:0x#{'%x' % (self.object_id << 1)} #{@format[1]}::#{to_a.inspect}>"
      else
        "<StructuredObject::Array:0x#{'%x' % (self.object_id << 1)} #{to_a.inspect}>"
      end
    end
  end
end
