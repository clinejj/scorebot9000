require "test_helper"

class Admin::SmsMessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
    Flipper.enable_actor(:sms_scoring, users(:organizer))
  end

  test "simulates a text and shows the reply" do
    post admin_sms_messages_path, params: { from: "909-555-0111", body: "WHO" }
    assert_redirected_to admin_sms_messages_path
    assert_match "Usain Bolt", flash[:notice]
    assert SmsMessage.inbound.last.simulated?
    get admin_sms_messages_path
    assert_response :success
    assert_match "(•••) •••-0111", response.body
  end
end
