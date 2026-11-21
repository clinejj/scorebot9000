require "test_helper"

class PrefixedIdTypeTest < ActiveSupport::TestCase
  setup do
    @type = PrefixedId::Type.new("usr")
    @uuid = SecureRandom.uuid_v7
  end

  test "casts a TypeID with the right prefix to its UUID" do
    assert_equal @uuid, @type.cast(TypeId.encode("usr", @uuid))
    assert_equal @uuid, @type.serialize(TypeId.encode("usr", @uuid))
  end

  test "casts raw UUIDs as usual" do
    assert_equal @uuid, @type.cast(@uuid)
  end

  test "casts a TypeID with the wrong prefix to nil" do
    assert_nil @type.cast(TypeId.encode("evt", @uuid))
  end

  test "casts garbage to nil" do
    assert_nil @type.cast("usr_nope")
    assert_nil @type.cast("nope")
  end
end
