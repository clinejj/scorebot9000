# A user's role on a series (applies to all its events) or a single event.
class Membership < ApplicationRecord
  has_prefixed_id :mbr

  ROLES = %w[scorekeeper organizer owner].freeze # ascending power

  enum :role, ROLES.index_with(&:itself), validate: true

  belongs_to :user
  belongs_to :resource, polymorphic: true

  validates :resource_type, inclusion: { in: %w[Series Event] }
  validates :user_id, uniqueness: { scope: %i[resource_type resource_id], message: "already has a role here" }

  def self.highest_role(roles)
    roles.map(&:to_s).max_by { |role| ROLES.index(role) || -1 }&.to_sym
  end

  def self.role_at_least?(role, minimum)
    role.present? && ROLES.index(role.to_s) >= ROLES.index(minimum.to_s)
  end
end
