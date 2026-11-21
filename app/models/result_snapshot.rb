# Frozen standings for an event. Finished events always render from their
# official snapshot, so later scoring changes never rewrite history.
#
# Columns hold the serialized Scoring::Result (see Scoring::Serializer):
# `standings` holds both the main and individual standings, `game_results`
# the per-game rows.
class ResultSnapshot < ApplicationRecord
  has_prefixed_id :snap

  enum :source, { computed: "computed", legacy_capture: "legacy_capture" }, prefix: :from, validate: true

  belongs_to :event

  scope :official, -> { where(official: true) }

  validates :computed_at, presence: true
  validates :event_id, uniqueness: { conditions: -> { where(official: true) } }, if: :official?

  def self.columns_from(payload)
    {
      standings: { "main" => payload["standings"], "individual" => payload["individual_standings"] },
      game_results: payload["games"]
    }
  end

  def standings_payload
    {
      "computed_at" => computed_at.utc.iso8601(3),
      "config" => scoring_config,
      "standings" => standings.is_a?(Hash) ? standings["main"] : standings,
      "individual_standings" => standings.is_a?(Hash) ? standings["individual"] : nil,
      "games" => game_results
    }
  end
end
