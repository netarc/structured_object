require "test_helper"

class TypeTest < Test::Unit::TestCase
  class Foo < StructuredObject
    struct do
      uint8  :bar
      uint8  [:x, :y, :z]
      uint32 :foo
      int16  [:a]
    end
  end

  class FooBar < StructuredObject
    struct do
      uint8 :bar, :default => 123
      uint8 :x, :default => "FOO"
      int8 :y, :default => 130
    end
  end

  class BarFoo < StructuredObject
    struct do
      uint32 :bar, :endian => :big_endian
      uint32 :foo, :endian => :little_endian
    end
  end

  context "types declarations in structs" do
    should "accept individual type declarations" do
      foo = Foo.new

      assert foo.respond_to?(:bar)
      assert foo.respond_to?(:foo)

      assert_equal 0, foo.bar
      assert_equal 0, foo.foo
    end

    should "accept multiple type declarations for a single type" do
      foo = Foo.new

      assert foo.respond_to?(:x)
      assert foo.respond_to?(:y)
      assert foo.respond_to?(:z)

      assert_equal 0, foo.x
      assert_equal 0, foo.y
      assert_equal 0, foo.z
    end

    should "accept a single type declaration in a multiple type declarative" do
      foo = Foo.new

      assert foo.respond_to?(:a)
      assert_equal 0, foo.a
    end

    should "throw an error with an invalid type" do
      assert_raises(StructuredObject::Errors::UnknownType) do
        class ErrorFoo < StructuredObject
          struct do
            foobar :lies
          end
        end
      end
    end

    should "throw an error with an invalid type attribute name" do
      assert_raises(StructuredObject::Errors::AttributeInvalid) do
        class ErrorFoo < StructuredObject
          struct { byte 123 }
        end
      end

      assert_raises(StructuredObject::Errors::AttributeInvalid) do
        class ErrorFoo < StructuredObject
          struct { byte "asdf" }
        end
      end

      assert_raises(StructuredObject::Errors::AttributeExists) do
        class ErrorFoo < StructuredObject
          struct do
            byte :foo
            byte :foo
          end
        end
      end
    end
  end

  context "type values" do
    should "allow setting of a type value and adhere to type enforcement" do
      foo = Foo.new

      foo.bar = 123
      assert_equal 123, foo.bar

      foo.bar = 260
      assert_equal 4, foo.bar

      foo.bar = -128
      assert_equal 128, foo.bar

      foo.a = 12345
      assert_equal 12345, foo.a

      foo.a = -32768
      assert_equal -32768, foo.a

      foo.a = 32768
      assert_equal -32768, foo.a

      foo.a = "abc"
      assert_equal 25185, foo.a
    end

    should "allow default values for types" do
      foo = FooBar.new

      assert_equal 123, foo.bar
      assert_equal 70, foo.x
      assert_equal -126, foo.y
    end

    should "allow endian set for types" do
      foo = BarFoo.new

      foo.bar = "\xDD\xBB\xCC\xAA"
      foo.foo = "\xDD\xBB\xCC\xAA"

      assert -574894934, foo.bar
      assert -1429423139, foo.foo
    end
  end
end
