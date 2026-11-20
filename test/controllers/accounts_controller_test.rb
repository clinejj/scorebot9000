require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  CODE = PhoneVerifier::FakeBackend::TEST_CODE

  test "requires sign-in" do
    get account_path
    assert_redirected_to new_session_path
  end

  test "shows your events and contact methods" do
    sign_in_as users(:alice)
    get account_path
    assert_response :success
    assert_match "2027 Clinelympic Games", response.body
    assert_match "Usain Bolt", response.body
  end

  test "updates your name" do
    sign_in_as users(:alice)
    patch account_path, params: { user: { name: "Alice A." } }
    assert_equal "Alice A.", users(:alice).reload.name
  end

  test "adds an email after verifying it" do
    sign_in_as users(:alice)
    post identifiers_path, params: { kind: "email", identifier: "alice@example.com" }
    assert_redirected_to verify_identifiers_path
    perform_enqueued_jobs
    code = ActionMailer::Base.deliveries.last.subject[/\d{6}/]
    post verify_identifiers_path, params: { code: code }
    assert_redirected_to account_path
    assert_equal "alice@example.com", users(:alice).reload.email
  end

  test "adding a phone that belongs to a legacy account merges the two" do
    alice_id = users(:alice).id
    sign_in_as users(:player)
    post identifiers_path, params: { kind: "phone", identifier: "909-555-0111" }
    post verify_identifiers_path, params: { code: CODE }
    assert_redirected_to account_path
    assert_not User.exists?(alice_id)
    assert_equal "+19095550111", users(:player).reload.phone
    assert_includes users(:player).participants, participants(:alice)
  end

  test "merge conflicts are explained" do
    sign_in_as users(:bob)
    post identifiers_path, params: { kind: "phone", identifier: "909-555-0111" }
    post verify_identifiers_path, params: { code: CODE }
    assert_redirected_to account_path
    assert_match "Couldn't combine accounts", flash[:alert]
    assert User.exists?(users(:alice).id)
  end
end
