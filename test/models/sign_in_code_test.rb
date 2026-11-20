require "test_helper"

class SignInCodeTest < ActiveSupport::TestCase
  test "issues a 6-digit code and stores only a digest" do
    record = SignInCode.issue!(email: "Someone@Example.com")
    assert_match(/\A\d{6}\z/, record.code)
    assert_equal "someone@example.com", record.email
    assert_not_equal record.code, record.code_digest
    assert_nil SignInCode.find(record.id).code
  end

  test "verifies the right code once" do
    record = SignInCode.issue!(email: "a@example.com")
    assert record.verify(record.code)
    assert_not record.reload.usable?
    assert_not record.verify(record.code)
  end

  test "tolerates spaces in the entered code" do
    record = SignInCode.issue!(email: "a@example.com")
    assert record.verify(record.code.insert(3, " "))
  end

  test "locks out after too many wrong guesses" do
    record = SignInCode.issue!(email: "a@example.com")
    code = record.code
    wrong = code == "000000" ? "111111" : "000000"
    SignInCode::MAX_ATTEMPTS.times { assert_not record.verify(wrong) }
    assert_not record.reload.usable?
    assert_not record.verify(code)
  end

  test "expires" do
    record = SignInCode.issue!(email: "a@example.com")
    travel SignInCode::TTL + 1.second do
      assert_not record.verify(record.code)
    end
  end

  test "issuing a new code expires older ones" do
    first = SignInCode.issue!(email: "a@example.com")
    second = SignInCode.issue!(email: "a@example.com")
    assert_not first.reload.usable?
    assert_equal second, SignInCode.latest_usable_for("a@example.com")
  end

  test "magic link token finds the code" do
    record = SignInCode.issue!(email: "a@example.com")
    assert_equal record, SignInCode.find_by_magic_link_token(record.magic_link_token)
    assert_nil SignInCode.find_by_magic_link_token("bogus")
  end
end
