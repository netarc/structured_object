require "test_helper"

class ArrayTest < Test::Unit::TestCase
  class Foo < StructuredObject
    struct do
      byte :bar, :default => 123, :array => {:fixed_size => 3}
      byte :barbar, :default => 123, :array => {:fixed_size => 5}

      struct :blocks, :array => {:fixed_size => 4} do
        byte :x, :default => 321
      end
    end
  end

  context "non-nested arrayed types" do
    should "allocate fixed size array and initialize with defaults" do
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

  context "non-nested array manipulation" do
    should "assign new array to fixed size array and enforce new values" do
      foo = Foo.new
      foo.bar = [1,321,2]

      assert_equal 1, foo.bar[0]
      assert_equal 65, foo.bar[1]
      assert_equal 2, foo.bar[2]
      assert_equal 3, foo.bar.size
    end

    should "maintain fixed size when adding new items and maintain expected" do
      foo = Foo.new
      foo.bar << 1
      foo.bar << 5

      assert_equal 3, foo.bar.size
      assert_equal [123, 1, 5], foo.bar
    end

    should "maintain fixed size when removing items from array" do
      foo = Foo.new
      foo.bar = [1,2,3]
      foo.bar.pop
      foo.bar.pop

      assert_equal 3, foo.bar.size
      assert_equal [1, 2, 123], foo.bar

      foo.barbar = [1,2,3,4,5]
      foo.barbar.slice!(2..3)

      assert_equal 5, foo.barbar.size
      assert_equal [1,2,5,123,123], foo.barbar
    end
  end

  context "non-nested arrayed structs" do
    should "allocate fixed size array and initialize with defaults" do
      foo = Foo.new

      assert_equal 4, foo.blocks.size
      assert_equal 65, foo.blocks[0].x
      assert_equal 65, foo.blocks[1].x
      assert_equal 65, foo.blocks[2].x
      assert_equal 65, foo.blocks[3].x
    end

    should "maintain seperate values" do
      foo = Foo.new
      foo.blocks[0].x = 123
      foo.blocks[1].x = 13
      foo.blocks[2].x = 23
      foo.blocks[3].x = 76

      assert_equal 123, foo.blocks[0].x
      assert_equal 13, foo.blocks[1].x
      assert_equal 23, foo.blocks[2].x
      assert_equal 76, foo.blocks[3].x
    end
  end

  context "non-nested struct array manipulation" do
    should "assign new array to fixed size array and enforce new values" do
      foo = Foo.new

      block1 = foo.blocks.new
      block1.x = 13
      block2 = foo.blocks.new
      block2.x = 76
      block3 = foo.blocks.new
      block3.x = 29
      foo.blocks = [block1, block2, block3]

      assert_equal block1, foo.blocks[0]
      assert_equal 13, foo.blocks[0].x
      assert_equal block2, foo.blocks[1]
      assert_equal 76, foo.blocks[1].x
      assert_equal block3, foo.blocks[2]
      assert_equal 29, foo.blocks[2].x
    end

    should "maintain fixed size when adding new items and maintain expected" do
      foo = Foo.new

      block1 = foo.blocks.new
      block1.x = 41
      foo.blocks << block1

      block2 = foo.blocks.new
      block2.x = 62
      foo.blocks << block2

      assert_equal 4, foo.blocks.size
      assert_equal 65, foo.blocks[0].x
      assert_equal 65, foo.blocks[1].x
      assert_equal 41, foo.blocks[2].x
      assert_equal 62, foo.blocks[3].x
    end

    should "maintain fixed size when removing items from array" do
      foo = Foo.new

      block1 = foo.blocks.new
      block1.x = 13
      block2 = foo.blocks.new
      block2.x = 76
      block3 = foo.blocks.new
      block3.x = 29
      block4 = foo.blocks.new
      block4.x = 33
      foo.blocks = [block1, block2, block3, block4]

      foo.blocks.pop
      foo.blocks.pop

      assert_equal 4, foo.blocks.size
      assert_equal 13, foo.blocks[0].x
      assert_equal 76, foo.blocks[1].x
      assert_equal 29, foo.blocks[2].x
      assert_equal 65, foo.blocks[3].x

      foo.blocks = [block1, block2, block3, block4]
      foo.blocks.slice!(1..2)

      assert_equal 4, foo.blocks.size
      assert_equal 13, foo.blocks[0].x
      assert_equal 33, foo.blocks[1].x
      assert_equal 65, foo.blocks[2].x
      assert_equal 65, foo.blocks[3].x
    end

    should "not accept incorrect types for array" do
      foo = Foo.new

      foo.blocks = [1,2]

      assert_equal 4, foo.blocks.size
      assert_equal 65, foo.blocks[0].x
      assert_equal 65, foo.blocks[1].x
      assert_equal 65, foo.blocks[2].x
      assert_equal 65, foo.blocks[3].x
    end
  end
end
