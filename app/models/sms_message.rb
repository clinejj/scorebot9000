# Inbound and outbound text messages (including imported legacy texts).
class SmsMessage < ApplicationRecord
  has_prefixed_id :sms

  enum :direction, { inbound: "inbound", outbound: "outbound" }, validate: true

  encrypts :from_number, deterministic: true
  encrypts :to_number, deterministic: true

  belongs_to :user, optional: true
  belongs_to :event, optional: true
  belongs_to :reply_to, class_name: "SmsMessage", optional: true
  has_one :reply, class_name: "SmsMessage", foreign_key: :reply_to_id, inverse_of: :reply_to, dependent: :nullify

  scope :recent, -> { order(created_at: :desc) }

  validates :twilio_sid, uniqueness: true, allow_nil: true
end
