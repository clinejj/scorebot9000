require "test_helper"

class PhoneSignInTest < ActionDispatch::IntegrationTest
  CODE = PhoneVerifier::FakeBackend::TEST_CODE

  test "signs in an existing phone-only player with a texted code" do
    post session_path, params: { identifier: "(909) 555-0100" }
    assert_redirected_to verify_session_path
    post verify_session_path, params: { code: CODE }
    assert_redirected_to root_url
    assert_equal users(:phone_only), Session.order(:created_at).last.user
    assert users(:phone_only).reload.phone_verified_at.present?
  end

  test "creates a new account for a new number" do
    assert_difference -> { User.count } do
      post session_path, params: { identifier: "909-555-0177" }
      post verify_session_path, params: { code: CODE }
    end
    assert_equal "+19095550177", User.order(:created_at).last.phone
  end

  test "rejects a wrong code" do
    post session_path, params: { identifier: "909-555-0100" }
    post verify_session_path, params: { code: "000000" }
    assert_response :unprocessable_entity
  end

  test "pausing phone login falls back to email" do
    Flipper.enable(:pause_phone_login)
    post session_path, params: { identifier: "909-555-0100" }
    assert_response :unprocessable_entity
    assert_select ".flash-alert", /email/
  end
end
