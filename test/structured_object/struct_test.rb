require "test_helper"

class StructTest < Test::Unit::TestCase
  class Foo < StructuredObject
    struct do
      struct :bar do
        byte :x, :default => 123
        struct :subbar do
          byte :x, :default => 213
          byte [:y, :z], :default => 111
        end
      end
    end
  end

  class FooStruct < StructuredObject
    struct do
      byte [:x, :y]
    end
  end

  class BarStruct < StructuredObject
    struct do
      byte :z
      struct :foo, FooStruct
    end
  end

  class BarProcStruct < StructuredObject
    struct do
      byte :z
      struct :foo, lambda {FooStruct}
    end
  end

  context "sub structs" do
    should "properly create nested structs and initialize them" do
      foo = Foo.new

      assert foo.bar.is_a?(StructuredObject)
      assert_equal 123, foo.bar.x

      assert foo.bar.subbar.is_a?(StructuredObject)
      assert_equal 213, foo.bar.subbar.x
      assert_equal 111, foo.bar.subbar.y
      assert_equal 111, foo.bar.subbar.z
    end

    should "throw an error when not passing a block or class for a sub struct" do
      assert_raises(StructuredObject::Errors::StructExpectedClass) do
        class ErrorFoo < StructuredObject
          struct do
            struct :subfoo
          end
        end
      end
    end

    should "create a nested struct with a Class instead of a block" do
      bar = BarStruct.new

      assert_equal 0, bar.z
      assert_equal 0, bar.foo.x
      assert_equal 0, bar.foo.y
    end

    should "create a nested struct with a proc supplying a Class instead of a block" do
      bar = BarProcStruct.new

      assert_equal 0, bar.z
      assert_equal 0, bar.foo.x
      assert_equal 0, bar.foo.y
    end
  end
end
