require "test_helper"

class BaseTest < Test::Unit::TestCase

  class Block < StructuredObject
    struct do
      byte [:x,:y,:z]
    end
  end

  class Foo < StructuredObject

    # when defining a struct or type the following options are available
    #  the following two options will covert the specified type/struct into an array
    #  :size   - denotes a fixed size array of specified length (The Array will have a minimum & maximum record count of :size)
    #  :length - denotes an un-fixed size array of initially specified length (The Array will initially have :length records)
    #
    # when defining a type the following options are available
    #  :read    - when retrieving this value it is always inferred from this
    #  :default - the default value assigned to this type when initialized
    #
    struct do
      # a fixed array of 3-bytes
      byte   :id, :length => 0

      # a 16-bit unsigned integer which value is read-only
#      uint16 :size, :read => lambda { blocks.size }
      # an un-fixed array of objects of size :struct
#      struct :blocks, :size => 3 do
#        byte [:x,:y,:z]
#      end
    end
  end

#   class Bar
#     include StructuredObject::Base

#     struct do
#       byte   :id, :length => 3
#       uint16 :size
#       array  :blocks, :length => lambda { size } do
#         uint16 :lparam
#         uint16 :rparam
#       end
#       array :triangles, :uint16, :length => lambda { size }
#     end
#   end

#   class FooBar < StructuredObject
#     struct do
#       byte :id, :length => 3
#       array :circles, lambda { Foo }
# #       union do
# #         struct do
# #           byte :a
# #           byte :b
# #           byte :g
# #           byte :r
# #         end
# #         uint32 :colour
# #       end
#     end
#   end

  context "initialization" do
    should "create from base class" do
      foo = Foo.new
      puts "created foo\n\r"

      puts "foo id: #{foo.id.inspect}"
      puts "foo id: #{foo.id.size}"
      foo.id << 1
      foo.id << 5
      foo.id << 321
      foo.id << 123
      puts "foo id: #{foo.id.inspect}"
      puts "foo id: #{foo.id.size}"

     end
  end
end
