require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "renders the sign-in form" do
    get new_session_path
    assert_response :success
    assert_select "input[name=identifier]"
  end

  test "signs in with an emailed code" do
    assert_enqueued_emails 1 do
      post session_path, params: { identifier: "Player@Example.com" }
    end
    assert_redirected_to verify_session_path

    perform_enqueued_jobs
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "player@example.com" ], mail.to
    assert_match(/\A\d{6} is your Scorebot sign-in code\z/, mail.subject)
    assert_includes mail.text_part.body.to_s, "/session/verify?token="
  end

  test "completes sign-in with the right code and creates the user" do
    post session_path, params: { identifier: "newbie@example.com" }
    perform_enqueued_jobs
    plain_code = ActionMailer::Base.deliveries.last.subject[/\d{6}/]

    assert_difference -> { User.count } => 1, -> { Session.count } => 1 do
      post verify_session_path, params: { code: plain_code }
    end
    assert_redirected_to root_url
    assert cookies[:session_id].present?
    assert_equal "newbie@example.com", User.order(:created_at).last.email
  end

  test "rejects a wrong code" do
    post session_path, params: { identifier: "player@example.com" }
    post verify_session_path, params: { code: "not-it" }
    assert_response :unprocessable_entity
    assert_select ".flash-alert", /didn't match/
    assert_nil cookies[:session_id].presence
  end

  test "signs in with the magic link" do
    code = SignInCode.issue!(email: "player@example.com")
    get verify_session_path(token: code.magic_link_token)
    assert_redirected_to root_url
    assert cookies[:session_id].present?
    assert_not code.reload.usable?
  end

  test "rejects a used magic link" do
    code = SignInCode.issue!(email: "player@example.com")
    code.consume!
    get verify_session_path(token: code.magic_link_token)
    assert_redirected_to new_session_path
  end

  test "rejects junk identifiers" do
    post session_path, params: { identifier: "hello" }
    assert_response :unprocessable_entity
  end

  test "phone sign-in is not available yet" do
    post session_path, params: { identifier: "909-726-7311" }
    assert_response :unprocessable_entity
    assert_select ".flash-alert", /Phone sign-in/
  end

  test "signs out" do
    sign_in_as users(:player)
    delete session_path
    assert_redirected_to root_path
    assert_equal 0, users(:player).sessions.count
  end
end
