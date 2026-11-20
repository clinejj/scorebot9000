# One submitted score. Entries are append-only: an "undo" or correction voids
# the entry (voided_at) instead of editing or deleting it. The game's
# attempt_policy decides which active entries count (latest, best, average).
class ScoreEntry < ApplicationRecord
  has_prefixed_id :scr

  enum :source, { sms: "sms", web: "web", organizer: "organizer", import: "import", reconciliation: "reconciliation" }, prefix: :from, validate: true

  belongs_to :game, touch: true
  belongs_to :participant, optional: true
  belongs_to :team, optional: true
  belongs_to :submitted_by_user, class_name: "User", optional: true
  belongs_to :voided_by_user, class_name: "User", optional: true

  scope :active, -> { where(voided_at: nil) }
  scope :chronological, -> { order(:created_at, :id) }

  validates :value, presence: true, numericality: { less_than_or_equal_to: ScoreValue::MAX, greater_than_or_equal_to: -ScoreValue::MAX }
  validate :exactly_one_competitor
  validate :competitor_matches_game

  def competitor
    participant || team
  end

  def voided?
    voided_at.present?
  end

  def void!(by: nil)
    update!(voided_at: Time.current, voided_by_user: by) unless voided?
  end

  def display_value
    game.format_value(value)
  end

  private
    def exactly_one_competitor
      errors.add(:base, "needs exactly one of participant or team") unless [ participant_id, team_id ].compact.size == 1
    end

    def competitor_matches_game
      return unless game

      if game.scored_by_team? && participant_id
        errors.add(:base, "#{game.name} is scored per team")
      elsif game.scored_by_individual? && team_id
        errors.add(:base, "#{game.name} is scored per player")
      end
      errors.add(:participant, "must be in the same event") if participant && participant.event_id != game.event_id
      errors.add(:team, "must be in the same event") if team && team.event_id != game.event_id
    end
end
