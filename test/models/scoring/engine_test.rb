require "test_helper"

module Scoring
  class EngineTest < ActiveSupport::TestCase
    # Tiny builder for engine inputs.
    class Builder
      attr_reader :games, :participants, :teams, :entries, :adjustments

      def initialize
        @games, @participants, @teams, @entries, @adjustments = [], [], [], [], []
        @clock = Time.utc(2027, 1, 9, 15)
      end

      def team(name)
        TeamInput.new(id: SecureRandom.uuid_v7, public_id: nil, name: name, color: nil).tap { |team| @teams << team }
      end

      def player(name, team = nil)
        ParticipantInput.new(id: SecureRandom.uuid_v7, public_id: nil, name: name, team_id: team&.id).tap { |player| @participants << player }
      end

      def game(name, direction: "higher_better", participation: "individual", aggregation: "sum", n: nil, attempts: "latest", weight: 1)
        GameInput.new(id: SecureRandom.uuid_v7, public_id: nil, name: name, position: @games.size + 1, direction: direction,
          participation: participation, team_aggregation: aggregation, team_aggregation_n: n, attempt_policy: attempts,
          weight: BigDecimal(weight.to_s), score_format: "decimal").tap { |game| @games << game }
      end

      def score(game, competitor, value)
        @clock += 1
        participant_id = competitor.is_a?(ParticipantInput) ? competitor.id : nil
        team_id = competitor.is_a?(TeamInput) ? competitor.id : nil
        @entries << EntryInput.new(game_id: game.id, participant_id: participant_id, team_id: team_id, value: BigDecimal(value.to_s), created_at: @clock)
      end

      def adjust(competitor, points)
        participant_id = competitor.is_a?(ParticipantInput) ? competitor.id : nil
        team_id = competitor.is_a?(TeamInput) ? competitor.id : nil
        @adjustments << AdjustmentInput.new(participant_id: participant_id, team_id: team_id, points: BigDecimal(points.to_s), reason: "test")
      end

      def run(config_hash = {})
        config = Config.new(config_hash)
        raise config.errors.to_sentence unless config.valid?

        Engine.new(config).call(games: games, participants: participants, teams: teams, entries: entries, adjustments: adjustments)
      end
    end

    setup { @b = Builder.new }

    def names(rows) = rows.map { |row| row.competitor.name }
    def places(rows) = rows.map(&:place)
    def game_row(result, game, name) = result.game_results.find { |r| r.game.id == game.id }.rows.find { |row| row.competitor.name == name }

    test "legacy preset reproduces the original Clinelympics scoring" do
      teams = %w[ANTS BEES CATS DOGS].index_with { |name| @b.team(name) }
      players = teams.transform_values { |team| [ @b.player("#{team.name}-1", team), @b.player("#{team.name}-2", team) ] }
      trivia = @b.game("Trivia")
      golf = @b.game("Golf", direction: "lower_better")

      # Trivia team totals (sum of members): ANTS 10, BEES 10, CATS 8, DOGS 5
      { "ANTS" => [ 6, 4 ], "BEES" => [ 10 ], "CATS" => [ 5, 3 ], "DOGS" => [ 5 ] }.each do |team, values|
        values.each_with_index { |value, i| @b.score(trivia, players[team][i], value) }
      end
      # Golf (lower wins): ANTS 3, BEES 4, CATS 4, DOGS 6
      { "ANTS" => 3, "BEES" => 4, "CATS" => 4, "DOGS" => 6 }.each { |team, value| @b.score(golf, players[team][0], value) }

      result = @b.run("preset" => "legacy_clinelympics")

      # Dense ranking: ties share a medal and don't use up a slot.
      assert_equal [ 0, 0, 1, 2 ], %w[ANTS BEES CATS DOGS].map { |team| game_row(result, trivia, team).medal }
      assert_equal [ 0, 1, 1, 2 ], %w[ANTS BEES CATS DOGS].map { |team| game_row(result, golf, team).medal }
      assert_equal BigDecimal(10), game_row(result, trivia, "ANTS").value
      # 3/2/1 points: ANTS 6, BEES 5, CATS 4, DOGS 2
      assert_equal %w[ANTS BEES CATS DOGS], names(result.standings)
      assert_equal [ 6, 5, 4, 2 ], result.standings.map { |row| row.total.to_i }
      assert_equal [ 1, 2, 3, 4 ], places(result.standings)
      assert_nil result.individual_standings
    end

    test "legacy ties on points and medals break by reverse name" do
      ants, bears = @b.team("ANTS"), @b.team("BEARS")
      trivia = @b.game("Trivia")
      @b.score(trivia, @b.player("a", ants), 5)
      @b.score(trivia, @b.player("b", bears), 5)
      result = @b.run("preset" => "legacy_clinelympics")
      assert_equal %w[BEARS ANTS], names(result.standings)
      assert_equal [ 1, 1 ], places(result.standings)
    end

    test "competition ranking skips places after ties" do
      trivia = @b.game("Trivia")
      %w[A B C].zip([ 10, 10, 8 ]).each { |name, value| @b.score(trivia, @b.player(name), value) }
      result = @b.run("basis" => "individual")
      rows = result.game_results.first.rows
      assert_equal [ 1, 1, 3 ], rows.map(&:place)
      assert_equal [ 0, 0, 2 ], rows.map(&:medal)
    end

    test "attempt policies pick latest, best or average" do
      latest = @b.game("Latest")
      best = @b.game("Best", direction: "lower_better", attempts: "best")
      average = @b.game("Average", attempts: "average")
      pat = @b.player("Pat")
      [ 5, 9, 7 ].each { |value| [ latest, best, average ].each { |game| @b.score(game, pat, value) } }
      result = @b.run("basis" => "individual")
      assert_equal [ 7, 5, 7 ], result.game_results.map { |r| r.rows.first.value.to_i }
    end

    test "team aggregation options" do
      big, small = @b.team("Big"), @b.team("Small")
      big_players = 3.times.map { |i| @b.player("big#{i}", big) }
      small_player = @b.player("small", small)
      sum = @b.game("Sum")
      avg = @b.game("Avg", aggregation: "average")
      top = @b.game("Top2", aggregation: "top_n_sum", n: 2)
      median = @b.game("Median", aggregation: "median")
      [ sum, avg, top, median ].each do |game|
        big_players.zip([ 4, 6, 8 ]).each { |player, value| @b.score(game, player, value) }
        @b.score(game, small_player, 7)
      end
      result = @b.run("basis" => "team")
      assert_equal 18, game_row(result, sum, "Big").value
      assert_equal 6, game_row(result, avg, "Big").value          # average evens out team size
      assert_equal 14, game_row(result, top, "Big").value         # best two: 8 + 6
      assert_equal 6, game_row(result, median, "Big").value
      assert_equal 1, game_row(result, avg, "Small").place        # 7 beats 6 on average
      assert_equal %w[big0 big1 big2], game_row(result, sum, "Big").contributors.map(&:name).sort
    end

    test "missing members can count as zero" do
      team = @b.team("T")
      scorer = @b.player("scorer", team)
      @b.player("absent", team)
      avg = @b.game("Avg", aggregation: "average")
      @b.score(avg, scorer, 10)
      assert_equal 10, game_row(@b.run("basis" => "team"), avg, "T").value
      assert_equal 5, game_row(@b.run("basis" => "team", "missing_members" => "zero"), avg, "T").value
    end

    test "team games score teams, and credit members in individual standings" do
      team = @b.team("Wheaties")
      alice = @b.player("Alice", team)
      quiz = @b.game("Quiz", participation: "team")
      @b.score(quiz, team, 9)
      result = @b.run("basis" => "team")
      assert_equal 9, game_row(result, quiz, "Wheaties").value
      assert_equal [ "Alice" ], names(result.individual_standings)
      assert_equal [ 1 ], result.individual_standings.first.medal_counts.first(1)
    end

    test "placement points with a table, linear points and game weights" do
      players = %w[A B C].map { |name| @b.player(name) }
      g1 = @b.game("G1")
      g2 = @b.game("G2", weight: 2)
      players.zip([ 3, 2, 1 ]).each { |player, value| @b.score(g1, player, value) }
      players.zip([ 1, 2, 3 ]).each { |player, value| @b.score(g2, player, value) }

      table = @b.run("basis" => "individual", "preset" => "placement_points")
      # A: 10 + 6*2 = 22, B: 8 + 8*2 = 24, C: 6 + 10*2 = 26
      assert_equal %w[C B A], names(table.standings)
      assert_equal [ 26, 24, 22 ], table.standings.map { |row| row.total.to_i }

      linear = @b.run("basis" => "individual", "preset" => "placement_points", "placement_points" => "linear")
      assert_equal [ 7, 6, 5 ], linear.standings.map { |row| row.total.to_i } # C: 1+3*2, B: 2+2*2, A: 3+1*2
    end

    test "average rank counts skipped games as last place and enforces min games" do
      a, b, c = @b.player("A"), @b.player("B"), @b.player("C")
      g1, g2 = @b.game("G1"), @b.game("G2")
      @b.score(g1, a, 10)
      @b.score(g1, b, 5)
      @b.score(g2, b, 10)
      @b.score(g2, c, 5)
      result = @b.run("basis" => "individual", "preset" => "average_rank")
      # A: (1 + 3)/2 = 2, B: (2 + 1)/2 = 1.5, C: (3 + 2)/2 = 2.5
      assert_equal %w[B A C], names(result.standings)
      assert_equal [ BigDecimal("1.5"), 2, BigDecimal("2.5") ], result.standings.map(&:total)

      strict = @b.run("basis" => "individual", "preset" => "average_rank", "missing_scores" => "ignore", "min_games" => 2)
      assert_equal "B", strict.standings.first.competitor.name
      assert_equal [ 1, nil, nil ], places(strict.standings)
      assert_equal [ true, false, false ], strict.standings.map(&:ranked)
    end

    test "normalized average puts different scales on 0-100" do
      a, b = @b.player("A"), @b.player("B")
      big = @b.game("Big numbers")
      small = @b.game("Small numbers", direction: "lower_better")
      @b.score(big, a, 1000)
      @b.score(big, b, 500)
      @b.score(small, a, 3)
      @b.score(small, b, 1)
      result = @b.run("basis" => "individual", "preset" => "normalized_average")
      assert_equal [ 50, 50 ], result.standings.map { |row| row.total.to_i }
      assert_equal 100, game_row(result, small, "B").normalized
    end

    test "adjustments change point totals" do
      a, b = @b.player("A"), @b.player("B")
      g = @b.game("G")
      @b.score(g, a, 10)
      @b.score(g, b, 5)
      @b.adjust(b, 2)
      result = @b.run("basis" => "individual", "preset" => "weighted_medals")
      assert_equal %w[B A], names(result.standings) # B: silver 2 + 2 = 4 > A: gold 3
      assert_equal BigDecimal(2), result.standings.first.adjustment_points
    end

    test "medal table ranks golds before everything else" do
      a, b = @b.player("A"), @b.player("B")
      g1, g2, g3 = @b.game("G1"), @b.game("G2"), @b.game("G3")
      c = @b.player("C")
      @b.score(g1, a, 3)
      @b.score(g1, b, 2)
      [ g2, g3 ].each do |game|
        @b.score(game, b, 2)
        @b.score(game, a, 1)
        @b.score(game, c, 3)
      end
      result = @b.run("basis" => "individual", "preset" => "olympic")
      # C: 2 gold; A: 1 gold 0 silver 2 bronze... A has gold in G1 only; B has silvers
      assert_equal "C", result.standings.first.competitor.name
      assert_equal [ 2, 0, 0 ], result.standings.first.medal_counts
    end

    test "competitors without scores still appear, at the bottom" do
      @b.player("Scorer")
      quiet = @b.player("Quiet")
      g = @b.game("G")
      @b.score(g, @b.participants.first, 1)
      result = @b.run("basis" => "individual")
      assert_equal "Quiet", result.standings.last.competitor.name
      assert_equal 0, result.standings.last.games_played
      assert_equal quiet.id, result.standings.last.competitor.id
    end

    test "per-game stats" do
      g = @b.game("G", direction: "lower_better")
      [ 4, 8, 6 ].each_with_index { |value, i| @b.score(g, @b.player("P#{i}"), value) }
      stats = @b.run("basis" => "individual").game_results.first.stats
      assert_equal [ 3, 6, 6, 4, 8 ], [ stats.count, stats.mean, stats.median, stats.best, stats.worst ].map(&:to_i)
    end
  end
end
