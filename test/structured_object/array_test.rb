require "test_helper"

class ArrayTest < Test::Unit::TestCase
  class Foo < StructuredObject
    struct do
      byte :bar, :size => 3, :default => 123
    end
  end

  context "arrayed types" do
    should "allocate fixed size array and initialize" do
      foo = Foo.new

      assert_equal 3, foo.bar.size
      assert_equal 123, foo.bar[0]
      assert_equal 123, foo.bar[1]
      assert_equal 123, foo.bar[2]
    end

    should "maintain seperate values" do
      foo = Foo.new
      foo.bar[0] = 123
      foo.bar[1] = 13
      foo.bar[2] = 23

      assert_equal 123, foo.bar[0]
      assert_equal 13, foo.bar[1]
      assert_equal 23, foo.bar[2]
    end
  end
end
