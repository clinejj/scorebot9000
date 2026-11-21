require "test_helper"

class IdentifierTest < ActiveSupport::TestCase
  test "parses emails" do
    identifier = Identifier.parse(" Me@Example.com ")
    assert identifier.email?
    assert_equal "me@example.com", identifier.value
  end

  test "parses phone numbers to E.164" do
    identifier = Identifier.parse("909-726-7311")
    assert identifier.phone?
    assert_equal "+19097267311", identifier.value
  end

  test "returns nil for junk" do
    assert_nil Identifier.parse("")
    assert_nil Identifier.parse("hello")
    assert_nil Identifier.parse("not@an@email")
    assert_nil Identifier.parse("12")
  end
end
