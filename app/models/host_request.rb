# An application to host events. Approving it enables the `hosting` Flipper
# flag for the user (plan section 7.6).
class HostRequest < ApplicationRecord
  has_prefixed_id :hreq

  enum :status, { pending: "pending", approved: "approved", declined: "declined" }, validate: true

  belongs_to :user
  belongs_to :reviewed_by_user, class_name: "User", optional: true

  validates :message, length: { maximum: 2000 }
  validate :one_open_request_per_user, on: :create

  after_create_commit -> { HostRequestMailer.with(host_request: self).submitted.deliver_later }

  def approve!(by:, sms: false)
    transaction do
      update!(status: "approved", reviewed_by_user: by, reviewed_at: Time.current)
      Flipper.enable_actor(:hosting, user)
      Flipper.enable_actor(:sms_scoring, user) if sms
      AdminAuditEvent.record!("host_request.approve", subject: user.public_id, user: by, sms: sms)
    end
    HostRequestMailer.with(host_request: self).approved.deliver_later if user.email
  end

  def decline!(by:)
    update!(status: "declined", reviewed_by_user: by, reviewed_at: Time.current)
    AdminAuditEvent.record!("host_request.decline", subject: user.public_id, user: by)
  end

  private
    def one_open_request_per_user
      errors.add(:base, "You already have a pending request") if user && HostRequest.pending.where(user: user).exists?
    end
end
