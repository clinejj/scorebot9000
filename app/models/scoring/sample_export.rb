module Scoring
  # Writes an event's results as a scoring sample (see Scoring::SampleData)
  # with teams renamed "Team 1", "Team 2", ... and players "Player 1", ...
  # Game settings, score values and who played what are kept; names, phone
  # numbers, emails and timestamps are not.
  #
  #   bin/rails scoring:export_sample EVENT=clinelympics-2019 > db/scoring_samples/default.json
  module SampleExport
    module_function

    def call(event)
      data = EventData.load(event)
      teams = data[:teams].each_with_index.to_h { |team, index| [ team.id, index ] }
      players = data[:participants].each_with_index.to_h { |participant, index| [ participant.id, index ] }
      games = data[:games].each_with_index.to_h { |game, index| [ game.id, index ] }

      {
        "source" => "Scrubbed from #{event.name} (#{Date.current.iso8601})",
        "games" => data[:games].map do |game|
          { "name" => game.name, "direction" => game.direction, "score_format" => game.score_format, "participation" => game.participation,
            "team_aggregation" => game.team_aggregation, "team_aggregation_n" => game.team_aggregation_n, "attempt_policy" => game.attempt_policy,
            "weight" => number(game.weight) }.compact
        end,
        "teams" => teams.values.map { |index| "Team #{index + 1}" },
        "players" => data[:participants].map { |participant| { "name" => "Player #{players[participant.id] + 1}", "team" => teams[participant.team_id] } },
        "scores" => data[:entries].sort_by(&:created_at).map do |entry|
          { "game" => games[entry.game_id], "player" => players[entry.participant_id], "team" => (teams[entry.team_id] unless entry.participant_id),
            "value" => ScoreValue.trim(entry.value) }.compact
        end
      }
    end

    # One record per line, so diffs of a refreshed sample stay readable.
    def to_json(event)
      sample = call(event)
      lines = ->(items) { "[\n#{items.map { |item| "    #{item.to_json}" }.join(",\n")}\n  ]" }
      <<~JSON
        {
          "source": #{sample["source"].to_json},
          "games": #{lines.call(sample["games"])},
          "teams": #{sample["teams"].to_json},
          "players": #{lines.call(sample["players"])},
          "scores": #{lines.call(sample["scores"])}
        }
      JSON
    end

    def number(value)
      decimal = BigDecimal(value.to_s)
      decimal.frac.zero? ? decimal.to_i : decimal.to_f
    end
  end
end
