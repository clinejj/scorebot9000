# Manual points bonus or penalty ("best uniforms +1"), shown openly in results.
class Adjustment < ApplicationRecord
  has_prefixed_id :adj

  broadcasts_refreshes_to :event

  belongs_to :event, touch: true
  belongs_to :participant, optional: true
  belongs_to :team, optional: true
  belongs_to :created_by_user, class_name: "User", optional: true

  validates :points, presence: true, numericality: { other_than: 0 }
  validates :reason, presence: true, length: { maximum: 140 }
  validate :exactly_one_competitor

  def competitor
    participant || team
  end

  private
    def exactly_one_competitor
      errors.add(:base, "needs exactly one of participant or team") unless [ participant_id, team_id ].compact.size == 1
    end
end
