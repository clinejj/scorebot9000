# The flags the app checks, with descriptions shown in the Flipper UI.
module FeatureFlags
  DESCRIPTIONS = {
    "hosting" => "Can create series and events. Enabled per user when a host request is approved.",
    "sms_scoring" => "SMS commands are accepted for events owned by these users (texts cost money on the platform Twilio account).",
    "sms_inbound" => "Kill switch: when disabled, inbound SMS is logged but not processed.",
    "phone_login" => "Kill switch: when disabled, sign-in falls back to email only.",
    "tv_mode" => "TV mode results page.",
    "sms_broadcasts" => "Proactive SMS broadcasts to event participants."
  }.freeze

  AUDITED_OPERATIONS = %i[enable disable add remove clear].freeze
end
