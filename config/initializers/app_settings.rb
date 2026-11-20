# Operator details shown on the privacy policy and SMS terms pages, which the
# Twilio A2P 10DLC campaign registration links to. Set via Fly secrets/env.
Rails.application.configure do
  config.x.operator_name = ENV.fetch("OPERATOR_NAME", "Scorebot 9000")
  config.x.support_email = ENV["SUPPORT_EMAIL"].presence
  config.x.sms_number = ENV["SMS_DISPLAY_NUMBER"].presence # e.g. "909-SCORE-11 (909-726-7311)"
end
