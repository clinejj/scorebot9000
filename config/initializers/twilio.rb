# Twilio credentials come from env vars (Fly secrets). See README.md.
Rails.application.configure do
  config.x.twilio.account_sid = ENV["TWILIO_ACCOUNT_SID"].presence
  config.x.twilio.auth_token = ENV["TWILIO_AUTH_TOKEN"].presence
  config.x.twilio.verify_service_sid = ENV["TWILIO_VERIFY_SERVICE_SID"].presence
  config.x.twilio.messaging_service_sid = ENV["TWILIO_MESSAGING_SERVICE_SID"].presence
end

# to_prepare re-runs after code reloads in development.
Rails.application.config.to_prepare do
  twilio = Rails.configuration.x.twilio
  PhoneVerifier.backend =
    if twilio.verify_service_sid
      PhoneVerifier::TwilioBackend.new(account_sid: twilio.account_sid, auth_token: twilio.auth_token, service_sid: twilio.verify_service_sid)
    elsif Rails.env.test?
      PhoneVerifier::FakeBackend.new(code: PhoneVerifier::FakeBackend::TEST_CODE)
    elsif Rails.env.development?
      PhoneVerifier::FakeBackend.new
    end
end
