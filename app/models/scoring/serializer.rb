module Scoring
  # Converts a Scoring::Result to and from JSON-safe hashes for result
  # snapshots. Competitors are stored by prefixed public ID, so snapshots
  # stay meaningful in Blazer and across environments. Decimals are strings.
  module Serializer
    module_function

    def dump(result)
      {
        "computed_at" => result.computed_at.utc.iso8601(3),
        "config" => result.config.to_h,
        "standings" => result.standings.map { |row| dump_standing(row) },
        "individual_standings" => result.individual_standings&.map { |row| dump_standing(row) },
        "games" => result.game_results.map { |game_result| dump_game(game_result) }
      }
    end

    def load(hash)
      config = Config.new(hash["config"])
      Result.new(
        config: config,
        standings: hash["standings"].map { |row| load_standing(row) },
        individual_standings: hash["individual_standings"]&.map { |row| load_standing(row) },
        game_results: hash["games"].map { |game| load_game(game) },
        computed_at: Time.iso8601(hash["computed_at"])
      )
    end

    def dump_competitor(competitor)
      { "type" => competitor.type, "id" => competitor.public_id, "name" => competitor.name,
        "team_id" => competitor.team_id && TypeId.encode("team", competitor.team_id), "color" => competitor.color }
    end

    def load_competitor(hash)
      Competitor.new(type: hash["type"], id: decode(hash["id"]), public_id: hash["id"], name: hash["name"],
        team_id: decode(hash["team_id"]), color: hash["color"])
    end

    def dump_standing(row)
      {
        "competitor" => dump_competitor(row.competitor), "place" => row.place, "ranked" => row.ranked,
        "medal_counts" => row.medal_counts, "medal_total" => num(row.medal_total), "medal_points" => num(row.medal_points),
        "placement_points" => num(row.placement_points), "average_rank" => num(row.average_rank),
        "normalized_average" => num(row.normalized_average), "adjustment_points" => num(row.adjustment_points),
        "total" => num(row.total), "games_played" => row.games_played, "best_place" => row.best_place
      }
    end

    def load_standing(hash)
      StandingRow.new(
        competitor: load_competitor(hash["competitor"]), place: hash["place"], ranked: hash["ranked"],
        medal_counts: hash["medal_counts"], medal_total: dec(hash["medal_total"]), medal_points: dec(hash["medal_points"]),
        placement_points: dec(hash["placement_points"]), average_rank: dec(hash["average_rank"]),
        normalized_average: dec(hash["normalized_average"]), adjustment_points: dec(hash["adjustment_points"]),
        total: dec(hash["total"]), games_played: hash["games_played"], best_place: hash["best_place"]
      )
    end

    def dump_game(game_result)
      game = game_result.game
      stats = game_result.stats
      {
        "game" => { "id" => game.public_id, "name" => game.name, "position" => game.position, "direction" => game.direction,
                    "participation" => game.participation, "team_aggregation" => game.team_aggregation,
                    "team_aggregation_n" => game.team_aggregation_n, "attempt_policy" => game.attempt_policy,
                    "weight" => num(BigDecimal(game.weight.to_s)), "score_format" => game.score_format },
        "rows" => game_result.rows.map do |row|
          { "competitor" => dump_competitor(row.competitor), "value" => num(row.value), "place" => row.place, "medal" => row.medal,
            "medal_points" => num(row.medal_points), "placement_points" => num(row.placement_points), "normalized" => num(row.normalized),
            "contributors" => row.contributors.map { |contributor| { "id" => contributor.public_id, "name" => contributor.name, "value" => num(contributor.value) } } }
        end,
        "stats" => { "count" => stats.count, "mean" => num(stats.mean), "median" => num(stats.median), "best" => num(stats.best), "worst" => num(stats.worst) }
      }
    end

    def load_game(hash)
      game = hash["game"]
      stats = hash["stats"]
      GameResult.new(
        game: GameInput.new(id: decode(game["id"]), public_id: game["id"], name: game["name"], position: game["position"],
          direction: game["direction"], participation: game["participation"], team_aggregation: game["team_aggregation"],
          team_aggregation_n: game["team_aggregation_n"], attempt_policy: game["attempt_policy"], weight: dec(game["weight"]),
          score_format: game["score_format"]),
        rows: hash["rows"].map do |row|
          GameRow.new(competitor: load_competitor(row["competitor"]), value: dec(row["value"]), place: row["place"], medal: row["medal"],
            medal_points: dec(row["medal_points"]), placement_points: dec(row["placement_points"]), normalized: dec(row["normalized"]),
            contributors: Array(row["contributors"]).map { |contributor| Contributor.new(public_id: contributor["id"], name: contributor["name"], value: dec(contributor["value"])) })
        end,
        stats: GameStats.new(count: stats["count"], mean: dec(stats["mean"]), median: dec(stats["median"]), best: dec(stats["best"]), worst: dec(stats["worst"]))
      )
    end

    def num(value)
      value && BigDecimal(value.to_s).to_s("F").sub(/\.0\z/, "")
    end

    def dec(value)
      value.nil? ? nil : BigDecimal(value.to_s)
    end

    def decode(public_id)
      public_id && TypeId.decode(public_id).last
    rescue TypeId::InvalidError
      nil
    end
  end
end
