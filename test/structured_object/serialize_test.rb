require "test_helper"

class SerializeTest < Test::Unit::TestCase
  class Foo < StructuredObject
    struct do
      uint16 :l1
      uint16 :l2
      int16 :l3
      byte :a1, :size => 3
      char :a2, :length => 0

      struct :s1 do
        byte :x
        char :y
      end

      struct :s2, :size => 2 do
        char :x
      end

      struct :s3, :length => 0 do
        char :x
      end
    end
  end

  context "should serialize object" do
    should "serialize" do
      goal = ""

      foo = Foo.new

      goal += "\x22\x22"
      foo.l1 = 8738

      goal += "\x33\x33"
      foo.l2 = 13107

      goal += "\x44\x44"
      foo.l3 = 17476

      goal += "\x00\x00\x01"
      foo.a1 = [0,0,1]

      goal += "\x02" + "\x99\x11"
      foo.a2 << -103
      foo.a2 << 17

      goal += "\x7B\xEC"
      foo.s1.x = 123
      foo.s1.y = -20

      goal += "\xF6\xEC"
      foo.s2[0].x = -10
      foo.s2[1].x = -20

      goal += "\x03" + "\xF6\xEC\xE2"
      foo.s3 = [foo.s3.new, foo.s3.new, foo.s3.new]
      foo.s3[0].x = -10
      foo.s3[1].x = -20
      foo.s3[2].x = -30

      assert_equal goal.unpack('H*')[0], foo.serialize_struct.unpack('H*')[0]
    end
  end

  context "should unserialize object" do
    should "unserialize" do
      goal = "\x22\x22\x33\x33\x44\x44\x00\x00\x01\x02\x99\x11\x7B\xEC\xF6\xEC\x03\xF6\xEC\xE2"

      foo = Foo.new
      foo.unserialize_struct(goal)

      assert_equal 8738, foo.l1
      assert_equal 13107, foo.l2
      assert_equal 17476, foo.l3

      assert_equal 3, foo.a1.size
      assert_equal 0, foo.a1[0]
      assert_equal 0, foo.a1[1]
      assert_equal 1, foo.a1[2]

      assert_equal 2, foo.a2.size
      assert_equal -103, foo.a2[0]
      assert_equal 17, foo.a2[1]

      assert_equal 123, foo.s1.x
      assert_equal -20, foo.s1.y

      assert_equal 2, foo.s2.size
      assert_equal -10, foo.s2[0].x
      assert_equal -20, foo.s2[1].x

      assert_equal 3, foo.s3.size
      assert_equal -10, foo.s3[0].x
      assert_equal -20, foo.s3[1].x
      assert_equal -30, foo.s3[2].x
    end
  end
end
