require "test_helper"

class Uuid7Test < ActiveSupport::TestCase
  test "generates version 7 RFC 9562 UUIDs" do
    uuid = Uuid7.generate
    assert_match(/\A\h{8}-\h{4}-7\h{3}-[89ab]\h{3}-\h{12}\z/, uuid)
  end

  test "is time-ordered" do
    earlier = Uuid7.generate(time: Time.utc(2012, 1, 7, 15))
    later = Uuid7.generate(time: Time.utc(2021, 1, 9, 15))
    assert_operator earlier, :<, later
  end

  test "mints from a historical timestamp" do
    time = Time.utc(2014, 1, 11, 18, 30, 5.123r)
    uuid = Uuid7.generate(time: time)
    assert_match(/\A\h{8}-\h{4}-7\h{3}-[89ab]\h{3}-\h{12}\z/, uuid)
    assert_equal time.floor(3), Uuid7.timestamp(uuid)
  end
end
