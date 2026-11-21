require "securerandom"

# UUIDv7 helpers. Every app primary key is a UUIDv7 minted in Ruby, so keys
# are time-ordered (index-friendly, and `first`/`last` stay meaningful) and
# known before insert.
module Uuid7
  module_function

  # A new UUIDv7. Pass `time:` to mint one for a historical record (e.g. a
  # legacy import) so ID order matches the record's real creation order.
  def generate(time: nil)
    uuid = SecureRandom.uuid_v7
    return uuid if time.nil?

    millis = format("%012x", (time.to_r * 1000).floor)
    "#{millis[0, 8]}-#{millis[8, 4]}#{uuid[13..]}"
  end

  def timestamp(uuid)
    Time.at(Rational(uuid.delete("-")[0, 12].to_i(16), 1000)).utc
  end
end
