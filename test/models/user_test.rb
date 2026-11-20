require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email and phone" do
    user = User.create!(email: "  Someone@Example.COM ", phone: "(909) 726-7311")
    assert_equal "someone@example.com", user.email
    assert_equal "+19097267311", user.phone
  end

  test "finds by email case-insensitively even though it's encrypted" do
    assert_equal users(:player), User.find_by(email: "PLAYER@example.com")
  end

  test "stores email as ciphertext" do
    raw = User.connection.select_value("SELECT email FROM users WHERE id = #{User.connection.quote(users(:player).id)}")
    assert_not_equal "player@example.com", raw
  end

  test "requires a contact method" do
    user = User.new(name: "Nobody")
    assert_not user.valid?
  end

  test "enforces unique email and phone" do
    assert_not User.new(email: "player@example.com").valid?
    assert_not User.new(phone: "+19095550100").valid?
  end

  test "from_verified_email! creates a new user" do
    user = User.from_verified_email!("new@example.com")
    assert user.persisted?
    assert user.email_verified_at.present?
  end

  test "from_verified_email! reuses an existing user" do
    assert_equal users(:player), User.from_verified_email!("player@example.com")
  end

  test "from_verified_email! links an organizer-mapped pending email" do
    user = User.from_verified_email!("mapped@example.com")
    assert_equal users(:mapped), user
    assert_equal "mapped@example.com", user.email
    assert_nil user.pending_email
    assert_equal "+19095550101", user.phone
  end

  test "has a prefixed public id that finders accept" do
    user = users(:player)
    assert_match(/\Ausr_[0-7][0-9a-hjkmnp-tv-z]{25}\z/, user.public_id)
    assert_equal user.public_id, user.to_param
    assert_equal user.public_id, user.flipper_id
    assert_equal user, User.find(user.public_id)
    assert_equal user, User.where(id: user.public_id).first
    assert_equal user, PrefixedId.locate(user.public_id)
  end

  test "rejects a prefixed id with the wrong prefix" do
    wrong = TypeId.encode("evt", users(:player).id)
    assert_raises(ActiveRecord::RecordNotFound) { User.find(wrong) }
    assert_nil User.find_by_public_id(wrong)
  end

  test "new records get UUIDv7 primary keys" do
    user = User.create!(email: "v7@example.com")
    assert_match(/\A\h{8}-\h{4}-7\h{3}-[89ab]\h{3}-\h{12}\z/, user.id)
  end

  test "display name falls back to email, then masked phone" do
    assert_equal "Pat Player", users(:player).display_name
    assert_equal "admin", users(:admin).display_name
    assert_equal "(•••) •••-0100", users(:phone_only).display_name
  end
end
