require "test_helper"

module Scoring
  class StandingsTest < ActiveSupport::TestCase
    test "computes live standings from the database" do
      event = events(:clinelympics_2027)
      result = event.standings
      assert_equal %w[Bears Wheaties], result.standings.map { |row| row.competitor.name } # Carol 15 beats Alice 12 in trivia
      trivia = result.game_results.find { |game| game.game.name == "Trivia" }
      assert_equal %w[Bears Wheaties], trivia.rows.map { |row| row.competitor.name }
      assert result.standings.first.competitor.public_id.start_with?("team_")
      assert_equal 4, result.individual_standings.size
    end

    test "voided entries don't count" do
      score_entries(:carol_trivia).void!
      event = events(:clinelympics_2027).reload
      assert_equal "Wheaties", event.standings.standings.first.competitor.name
    end

    test "serializer round-trips a result" do
      result = Standings.compute(events(:clinelympics_2027))
      restored = Serializer.load(JSON.parse(Serializer.dump(result).to_json))
      assert_equal result.standings.map { |row| [ row.competitor.public_id, row.place, row.total, row.medal_counts ] },
        restored.standings.map { |row| [ row.competitor.public_id, row.place, row.total, row.medal_counts ] }
      assert_equal result.game_results.map { |game| game.rows.map(&:value) }, restored.game_results.map { |game| game.rows.map(&:value) }
      assert_equal result.standings.first.competitor.id, restored.standings.first.competitor.id
    end
  end
end
