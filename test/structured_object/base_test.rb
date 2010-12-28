require "test_helper"

class BaseTest < Test::Unit::TestCase
  class BaseFoo < StructuredObject
    struct do
      byte :x
    end
  end

  class SuperFoo < BaseFoo
    struct do
      byte :y
    end
  end

  class Block < StructuredObject
    struct do
      byte [:x,:y,:z]
    end
  end

  class BitObj < StructuredObject
    struct do
      bit :reserved1
      # These 2 flags are only valid in Stand Alone players with Version 10+
      bit :use_direct_blit
      bit :use_gpu
      #
      bit :has_metadata
      bit :actionscript3
      bit :reserved2, :array => {:fixed_size => 2}
      bit :use_network
      bit :reserved3, :array => {:fixed_size => 24}
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
      byte   :id, :array => {:fixed_size => 3}

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

    end
  end
end
