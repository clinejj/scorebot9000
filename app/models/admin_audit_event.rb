# Who changed what in the admin tools (Flipper changes, admin grants, ...).
class AdminAuditEvent < ApplicationRecord
  belongs_to :user, optional: true

  def self.record!(action, subject: nil, user: Current.user, **metadata)
    create!(action: action, subject: subject&.to_s, user: user, metadata: metadata)
  end
end
