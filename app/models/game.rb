# One competition inside an event. `position` is the number players text in
# "SCORE <position> <value>".
class Game < ApplicationRecord
  has_prefixed_id :game

  enum :direction, { higher_better: "higher_better", lower_better: "lower_better" }, validate: true
  enum :score_format, { integer: "integer", decimal: "decimal", time: "time", placement: "placement" }, prefix: :format, validate: true
  enum :participation, { individual: "individual", team: "team" }, prefix: :scored_by, validate: true
  enum :team_aggregation, { sum: "sum", average: "average", best: "best", top_n_sum: "top_n_sum", median: "median" }, prefix: :aggregate, validate: true
  enum :attempt_policy, { latest: "latest", best: "best", average: "average" }, prefix: :attempts, validate: true
  enum :status, { upcoming: "upcoming", open: "open", locked: "locked", final: "final" }, validate: true

  belongs_to :event, touch: true
  has_many :score_entries, dependent: :destroy

  has_rich_text :description

  before_validation :assign_position, on: :create

  validates :name, presence: true, length: { maximum: 80 }
  validates :position, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :event_id }
  validates :weight, numericality: { greater_than_or_equal_to: 0 }
  validates :team_aggregation_n, numericality: { only_integer: true, greater_than: 0 }, if: :aggregate_top_n_sum?

  def to_param
    position.to_s
  end

  # Players can submit while the event is live and the game is open.
  def open_for_players?
    open? && event.live?
  end

  # Organizers can enter or correct scores until the event is finalized.
  def open_for_organizers?
    !event.finished?
  end

  def parse_value(input)
    ScoreValue.parse(input, score_format)
  end

  def format_value(value)
    ScoreValue.format(value, score_format)
  end

  def score_hint
    case score_format
    when "time" then "a time like 1:23.45"
    when "placement" then "a finishing place like 1"
    when "decimal" then "a number like 12.5"
    else "a whole number"
    end
  end

  private
    def assign_position
      self.position ||= (event&.games&.maximum(:position) || 0) + 1
    end
end
