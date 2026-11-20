# The flags the app checks, with descriptions shown in the Flipper UI.
# Kill switches are "pause_*" flags, so a fresh deploy works without
# enabling anything; enabling one turns the feature off.
module FeatureFlags
  DESCRIPTIONS = {
    "hosting" => "Can create series and events. Enabled per user when a host request is approved.",
    "sms_scoring" => "SMS commands are accepted for events owned by these users (texts cost money on the platform Twilio account).",
    "pause_sms_inbound" => "Kill switch: when enabled, inbound SMS is logged but not processed.",
    "pause_phone_login" => "Kill switch: when enabled, sign-in is email only (stops Twilio Verify spend).",
    "sms_broadcasts" => "Proactive SMS broadcasts to event participants."
  }.freeze

  AUDITED_OPERATIONS = %i[enable disable add remove clear].freeze

  # Makes every flag show up in the Flipper UI (idempotent).
  def self.define_all!
    DESCRIPTIONS.each_key { |key| Flipper.add(key) }
  end
end
