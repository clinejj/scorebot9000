require "test_helper"

class ScoreEntryTest < ActiveSupport::TestCase
  test "requires exactly one competitor" do
    entry = ScoreEntry.new(game: games(:trivia), value: 1, participant: participants(:alice), team: teams(:wheaties))
    assert_not entry.valid?
  end

  test "the database also enforces one competitor" do
    assert_raises(ActiveRecord::StatementInvalid) do
      ScoreEntry.insert_all!([ { id: Uuid7.generate, game_id: games(:trivia).id, value: 1, created_at: Time.current, updated_at: Time.current } ])
    end
  end

  test "competitor must match the game's participation" do
    assert_not ScoreEntry.new(game: games(:team_quiz), value: 1, participant: participants(:alice)).valid?
    assert_not ScoreEntry.new(game: games(:trivia), value: 1, team: teams(:wheaties)).valid?
    assert ScoreEntry.new(game: games(:team_quiz), value: 1, team: teams(:wheaties)).valid?
  end

  test "competitor must be in the game's event" do
    assert_not ScoreEntry.new(game: games(:legacy_trivia), value: 1, participant: participants(:alice)).valid?
  end

  test "void! marks the entry voided once" do
    entry = score_entries(:alice_trivia)
    entry.void!(by: users(:alice))
    assert entry.voided?
    assert_not_includes ScoreEntry.active, entry
  end

  test "formats its value with the game format" do
    entry = ScoreEntry.new(game: games(:relay), value: BigDecimal("83.45"))
    assert_equal "1:23.45", entry.display_value
  end
end
