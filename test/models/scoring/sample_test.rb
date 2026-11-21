require "test_helper"

module Scoring
  class SampleTest < ActiveSupport::TestCase
    test "the committed sample ranks under every preset, by team and by player" do
      sample = SampleData.load
      assert sample.source.present?
      Config::PRESETS.each_key do |preset|
        [ true, false ].each do |uses_teams|
          config = Config.from({ "preset" => preset }, uses_teams: uses_teams)
          result = Engine.new(config).call(**sample.inputs)
          assert result.standings.any?(&:place), "#{preset} (teams: #{uses_teams}) ranked no one"
        end
      end
    end

    test "exports scrub names but keep the results" do
      event = events(:clinelympics_2027)
      json = SampleExport.to_json(event)
      names = event.teams.pluck(:name) + event.participants.pluck(:alias_name)
      names.each { |name| assert_not_includes json, name }
      assert_not_includes json, "+1909"

      exported = Engine.new(event.scoring_config).call(**SampleData.inputs(JSON.parse(json)))
      live = Standings.compute(event)
      assert_equal live.standings.map { |row| [ row.place, row.total ] }, exported.standings.map { |row| [ row.place, row.total ] }
      assert_equal live.game_results.map { |game| game.rows.size }, exported.game_results.map { |game| game.rows.size }
    end

    test "previews use the event's own scores once it has some" do
      event = events(:clinelympics_2027)
      assert_not Preview.call(event.scoring_config, event: event).sample?

      draft = events(:draft_party)
      preview = Preview.call(draft.scoring_config, event: draft)
      assert preview.sample?
      assert preview.result.standings.any?
    end

    test "previews report settings that won't work" do
      config = Config.from({ "preset" => "olympic", "ranking" => "sideways" })
      preview = Preview.call(config)
      assert_nil preview.result
      assert_match "ranking", preview.config.errors.to_sentence
    end
  end
end
