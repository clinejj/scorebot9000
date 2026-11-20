require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "assigns the next position" do
    game = events(:clinelympics_2027).games.create!(name: "Cornhole")
    assert_equal 5, game.position
    assert_equal "5", game.to_param
  end

  test "positions are unique per event" do
    assert_not Game.new(event: events(:clinelympics_2027), name: "Dup", position: 1).valid?
  end

  test "players can submit only while the event is live and the game open" do
    assert games(:trivia).open_for_players?
    games(:trivia).update!(status: "locked")
    assert_not games(:trivia).open_for_players?
    assert games(:trivia).open_for_organizers?
    assert_not games(:legacy_trivia).open_for_organizers?
  end

  test "top_n_sum needs n" do
    game = games(:trivia)
    game.team_aggregation = "top_n_sum"
    assert_not game.valid?
    game.team_aggregation_n = 2
    assert game.valid?
  end
end
