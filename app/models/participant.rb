# A user's registration in an event: their public alias and (optional) team.
class Participant < ApplicationRecord
  has_prefixed_id :ptc

  enum :alias_source, { random: "random", chosen: "chosen", real_name: "real_name", import: "import" }, prefix: :alias_from, validate: true
  enum :registered_via, { sms: "sms", web: "web", organizer: "organizer", import: "import" }, prefix: :via, validate: true

  belongs_to :event, touch: true
  belongs_to :user
  belongs_to :team, optional: true
  has_many :score_entries, dependent: :destroy
  has_many :adjustments, dependent: :destroy

  normalizes :alias_name, with: ->(name) { name.squish }

  validates :alias_name, presence: true, length: { maximum: 60 },
    uniqueness: { scope: :event_id, case_sensitive: false, message: "is already taken in this event" }
  validates :user_id, uniqueness: { scope: :event_id, message: "is already registered for this event" }
  validate :team_belongs_to_event

  def display_name
    alias_name
  end

  private
    def team_belongs_to_event
      errors.add(:team, "must be in the same event") if team && team.event_id != event_id
    end
end
