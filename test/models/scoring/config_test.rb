require "test_helper"

module Scoring
  class ConfigTest < ActiveSupport::TestCase
    test "defaults to the olympic preset and the event's basis" do
      assert_equal "medal_table", Config.new({}).standings_method
      assert_equal "team", Config.new({}, uses_teams: true).basis
      assert_equal "individual", Config.new({}, uses_teams: false).basis
    end

    test "presets merge with overrides" do
      config = Config.new({ "preset" => "weighted_medals", "ranking" => "dense" })
      assert_equal "weighted_medals", config.standings_method
      assert config.dense?
      assert_equal "weighted_medals", config.to_h["preset"]
    end

    test "legacy preset" do
      config = Config.new({ "preset" => "legacy_clinelympics" })
      assert config.team_basis?
      assert config.dense?
      assert_equal %w[medals name_desc], config.tiebreakers
      assert_not config.show_individual_standings?
    end

    test "medals from legacy CSV get N..1 points" do
      medals = Config.medals_from_names("Gold,Silver,Bronze")
      assert_equal [ 3, 2, 1 ], medals.map { |medal| medal["points"] }
      assert_equal %w[Gold Silver Bronze], medals.map { |medal| medal["name"] }
    end

    test "reports invalid settings" do
      config = Config.new({ "standings" => "vibes", "ranking" => "random", "tiebreakers" => [ "coin_flip" ], "medals" => [ { "name" => "" } ] })
      assert_not config.valid?
      assert_equal 4, config.errors.size
    end

    test "placement points accept linear" do
      assert_nil Config.new({ "placement_points" => "linear" }).placement_points
      assert_not Config.new({ "placement_points" => "lots" }).valid?
    end

    test "events validate their scoring config" do
      event = events(:clinelympics_2027)
      event.scoring = { "standings" => "vibes" }
      assert_not event.valid?
      assert_includes event.errors[:scoring].first, "standings"
    end

    test "preset options hide legacy presets" do
      assert_not Config.preset_options.map(&:last).any? { |key| key.start_with?("legacy") }
    end
  end
end
