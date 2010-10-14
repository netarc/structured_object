class StructuredObject
  # Array is a type enforcement for an array of data
  class Array
    include Enumerable

    def initialize(instance, format=[])
#      puts "Creating Array with format: #{format.inspect}"
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

    # Set our array to new values
    def value=(new_value)
      @data = new_value
    end

    # Enforce the size constraints on the array
    def _enforce_size!(position=:else)
      if @type == :type
        unless @options[:size].nil?
          # Ensure we are at min size
          value_helper = self.new
          while @data.size < @options[:size]
            @data << value_helper.value
          end
          # Ensure we are at miax size
          while @data.size > @options[:size]
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
        _enforce_size!
      elsif @type == :struct
        puts "converting struct array to array"
        #       raise StandardError.new("unsupported") unless @type == :type
      end
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
