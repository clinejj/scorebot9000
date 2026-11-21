require "test_helper"

class TypeIdTest < ActiveSupport::TestCase
  # Vectors from the TypeID spec (https://github.com/jetify-com/typeid/tree/main/spec).
  VECTORS = {
    "00000000-0000-0000-0000-000000000000" => "00000000000000000000000000",
    "00000000-0000-0000-0000-000000000001" => "00000000000000000000000001",
    "00000000-0000-0000-0000-000000000020" => "00000000000000000000000010",
    "ffffffff-ffff-ffff-ffff-ffffffffffff" => "7zzzzzzzzzzzzzzzzzzzzzzzzz",
    "01890a5d-ac96-774b-bcce-b302099a8057" => "01h455vb4pex5vsknk084sn02q"
  }.freeze

  test "encodes spec vectors" do
    VECTORS.each do |uuid, suffix|
      assert_equal "usr_#{suffix}", TypeId.encode("usr", uuid)
    end
  end

  test "decodes spec vectors" do
    VECTORS.each do |uuid, suffix|
      assert_equal [ "usr", uuid ], TypeId.decode("usr_#{suffix}")
    end
  end

  test "round-trips random UUIDv7s" do
    20.times do
      uuid = SecureRandom.uuid_v7
      assert_equal [ "evt", uuid ], TypeId.decode(TypeId.encode("evt", uuid))
    end
  end

  test "allows underscores inside the prefix" do
    assert_equal [ "host_req", VECTORS.keys.last ], TypeId.decode("host_req_01h455vb4pex5vsknk084sn02q")
  end

  test "rejects malformed input" do
    [
      "01h455vb4pex5vsknk084sn02q",          # no prefix
      "usr_01h455vb4pex5vsknk084sn02",       # too short
      "usr_81h455vb4pex5vsknk084sn02q",      # first char > 7 overflows 128 bits
      "usr_01h455vb4pex5vsknk084sn0iq",      # 'i' is not in the alphabet
      "Usr_01h455vb4pex5vsknk084sn02q",      # uppercase prefix
      "usr__01h455vb4pex5vsknk084sn02q",     # prefix ends with underscore
      ""
    ].each do |bad|
      assert_raises(TypeId::InvalidError, bad) { TypeId.decode(bad) }
      assert_not TypeId.valid?(bad)
    end
  end

  test "valid? checks the expected prefix" do
    id = TypeId.encode("usr", SecureRandom.uuid_v7)
    assert TypeId.valid?(id, prefix: "usr")
    assert_not TypeId.valid?(id, prefix: "evt")
  end

  test "rejects bad prefixes and non-UUIDs on encode" do
    assert_raises(TypeId::InvalidError) { TypeId.encode("USR", SecureRandom.uuid) }
    assert_raises(TypeId::InvalidError) { TypeId.encode("usr", "not-a-uuid") }
  end
end
