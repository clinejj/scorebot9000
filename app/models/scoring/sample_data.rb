module Scoring
  # Engine inputs from a committed sample event (db/scoring_samples/*.json),
  # for previewing scoring settings before an event has scores of its own.
  # Samples hold no personal data: Scoring::SampleExport writes them with
  # teams and players renamed.
  module SampleData
    DIR = Rails.root.join("db/scoring_samples")
    EPOCH = Time.utc(2027, 1, 1)

    Sample = Data.define(:source, :inputs)

    module_function

    def load(name = "default")
      raw = JSON.parse(DIR.join("#{File.basename(name)}.json").read)
      Sample.new(source: raw["source"], inputs: inputs(raw))
    end

    def inputs(raw)
      teams = raw["teams"].each_with_index.map do |name, index|
        TeamInput.new(id: "sample-team-#{index}", public_id: nil, name: name, color: Team::COLORS[index % Team::COLORS.size])
      end
      participants = raw["players"].each_with_index.map do |player, index|
        ParticipantInput.new(id: "sample-player-#{index}", public_id: nil, name: player["name"], team_id: player["team"] && teams[player["team"]].id)
      end
      games = raw["games"].each_with_index.map do |game, index|
        GameInput.new(id: "sample-game-#{index}", public_id: nil, name: game["name"], position: index + 1,
          direction: game["direction"], participation: game["participation"] || "individual",
          team_aggregation: game["team_aggregation"] || "sum", team_aggregation_n: game["team_aggregation_n"],
          attempt_policy: game["attempt_policy"] || "latest", weight: BigDecimal((game["weight"] || 1).to_s),
          score_format: game["score_format"] || "decimal")
      end
      entries = raw["scores"].each_with_index.map do |score, index|
        EntryInput.new(game_id: games[score["game"]].id, participant_id: score["player"] && participants[score["player"]].id,
          team_id: score["team"] && teams[score["team"]].id, value: BigDecimal(score["value"].to_s), created_at: EPOCH + index)
      end
      { games: games, participants: participants, teams: teams, entries: entries, adjustments: [] }
    end
  end
end
