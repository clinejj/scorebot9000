# Frozen standings for an event. Finished events always render from their
# official snapshot, so later scoring changes never rewrite history.
class ResultSnapshot < ApplicationRecord
  has_prefixed_id :snap

  enum :source, { computed: "computed", legacy_capture: "legacy_capture" }, prefix: :from, validate: true

  belongs_to :event

  scope :official, -> { where(official: true) }

  validates :computed_at, presence: true
  validates :event_id, uniqueness: { conditions: -> { where(official: true) } }, if: :official?
end
