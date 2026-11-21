# An application to host events. Approving it enables the `hosting` Flipper
# flag for the user (plan section 7.6).
class HostRequest < ApplicationRecord
  has_prefixed_id :hreq

  enum :status, { pending: "pending", approved: "approved", declined: "declined" }, validate: true

  belongs_to :user
  belongs_to :reviewed_by_user, class_name: "User", optional: true

  validates :message, length: { maximum: 2000 }
end
