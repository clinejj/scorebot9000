# Scoring is pure Ruby: plain data in, standings out (plan section 8). Nothing
# under Scoring:: touches the database except Scoring::EventData (loading) and
# Scoring::Standings (caching and snapshots).
module Scoring
  GameInput = Data.define(:id, :public_id, :name, :position, :direction, :participation, :team_aggregation,
    :team_aggregation_n, :attempt_policy, :weight, :score_format) do
    def higher_better? = direction == "higher_better"
    def team? = participation == "team"
  end
  ParticipantInput = Data.define(:id, :public_id, :name, :team_id)
  TeamInput = Data.define(:id, :public_id, :name, :color)
  EntryInput = Data.define(:game_id, :participant_id, :team_id, :value, :created_at)
  AdjustmentInput = Data.define(:participant_id, :team_id, :points, :reason)

  Competitor = Data.define(:type, :id, :public_id, :name, :team_id, :color) do
    def team? = type == "team"
  end
  Contributor = Data.define(:public_id, :name, :value)
  GameRow = Data.define(:competitor, :value, :place, :medal, :medal_points, :placement_points, :normalized, :contributors)
  GameStats = Data.define(:count, :mean, :median, :best, :worst)
  GameResult = Data.define(:game, :rows, :stats)
  StandingRow = Data.define(:competitor, :place, :ranked, :medal_counts, :medal_total, :medal_points, :placement_points,
    :average_rank, :normalized_average, :adjustment_points, :total, :games_played, :best_place)
  Result = Data.define(:config, :standings, :individual_standings, :game_results, :computed_at)
end
