require "test_helper"

class HostRequestsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "requires sign-in" do
    get host_path
    assert_redirected_to new_session_path
  end

  test "approved hosts go straight to creating an event" do
    Flipper.enable_actor(:hosting, users(:player))
    sign_in_as users(:player)
    get host_path
    assert_redirected_to new_manage_event_path
  end

  test "others request access, which emails the admins" do
    sign_in_as users(:player)
    get host_path
    assert_response :success
    assert_enqueued_emails 1 do
      post host_path, params: { host_request: { message: "Backyard games in June" } }
    end
    assert_redirected_to host_path
    follow_redirect!
    assert_match "waiting for review", response.body
    assert_equal "Backyard games in June", users(:player).host_requests.sole.message
  end

  test "one pending request at a time" do
    users(:player).host_requests.create!(message: "first")
    sign_in_as users(:player)
    post host_path, params: { host_request: { message: "second" } }
    assert_response :unprocessable_entity
  end
end

class Admin::HostRequestsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @request_record = users(:player).host_requests.create!(message: "Please")
    sign_in_as users(:admin)
  end

  test "approving enables hosting (and optionally SMS) and emails the host" do
    get admin_host_requests_path
    assert_match "Please", response.body
    assert_enqueued_email_with HostRequestMailer, :approved, params: { host_request: @request_record } do
      patch admin_host_request_path(@request_record), params: { decision: "approve", sms: "1" }
    end
    assert @request_record.reload.approved?
    assert Flipper.enabled?(:hosting, users(:player))
    assert Flipper.enabled?(:sms_scoring, users(:player))
    assert_equal "host_request.approve", AdminAuditEvent.last.action
  end

  test "declining" do
    patch admin_host_request_path(@request_record), params: { decision: "decline" }
    assert @request_record.reload.declined?
    assert_not Flipper.enabled?(:hosting, users(:player))
  end
end
