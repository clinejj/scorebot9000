require "test_helper"

class SmsWebhooksControllerTest < ActionDispatch::IntegrationTest
  TOKEN = "test-twilio-auth-token"

  setup do
    @original_token = Rails.configuration.x.twilio.auth_token
    Rails.configuration.x.twilio.auth_token = TOKEN
    Flipper.enable_actor(:sms_scoring, users(:organizer))
  end

  teardown { Rails.configuration.x.twilio.auth_token = @original_token }

  def params_for(body, sid: "SM#{SecureRandom.hex(8)}")
    { "From" => "+19095550111", "To" => "+19097267311", "Body" => body, "MessageSid" => sid, "AccountSid" => "AC123" }
  end

  def signed_post(path, params)
    url = "http://www.example.com#{path}"
    signature = Twilio::Security::RequestValidator.new(TOKEN).build_signature_for(url, params)
    post path, params: params, headers: { "X-Twilio-Signature" => signature }
  end

  test "valid signed requests get a TwiML reply" do
    signed_post "/twilio/sms", params_for("WHO")
    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_match(/\AYou're Usain Bolt/, Nokogiri::XML(response.body).at("Message").text)
  end

  test "the legacy /inbound URL works too" do
    signed_post "/inbound", params_for("GAMES")
    assert_response :success
    assert_match "Trivia", response.body
  end

  test "unsigned or forged requests are rejected" do
    post "/twilio/sms", params: params_for("ADMIN START CLINE27")
    assert_response :forbidden
    post "/twilio/sms", params: params_for("WHO"), headers: { "X-Twilio-Signature" => "forged" }
    assert_response :forbidden
    assert_equal 0, SmsMessage.count
  end

  test "carrier keywords get an empty TwiML response" do
    signed_post "/twilio/sms", params_for("STOP")
    assert_response :success
    assert_no_match "<Message>", response.body
  end

  test "refuses to run without an auth token configured" do
    Rails.configuration.x.twilio.auth_token = nil
    post "/twilio/sms", params: params_for("WHO")
    assert_response :service_unavailable
  end
end
