require "test_helper"

class Manage::GamesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "adds, edits, reorders and deletes games" do
    event = events(:draft_party)
    post manage_event_games_path(event), params: { game: { name: "Cornhole", direction: "higher_better", score_format: "integer", participation: "individual" } }
    post manage_event_games_path(event), params: { game: { name: "Golf", direction: "lower_better", score_format: "integer", participation: "individual" } }
    assert_equal %w[Cornhole Golf], event.games.reload.map(&:name)

    patch move_manage_event_game_path(event, 2), params: { direction: "up" }
    assert_equal %w[Golf Cornhole], event.games.reload.map(&:name)

    patch manage_event_game_path(event, 1), params: { game: { name: "Mini Golf", weight: "2" } }
    assert_equal BigDecimal(2), event.games.find_by(position: 1).weight

    delete manage_event_game_path(event, 1)
    assert_equal [ [ 1, "Cornhole" ] ], event.games.reload.map { |game| [ game.position, game.name ] }
  end

  test "game numbers are locked once live, and games with scores can't be deleted" do
    event = events(:clinelympics_2027)
    patch move_manage_event_game_path(event, 2), params: { direction: "up" }
    assert_match "locked", flash[:alert]
    delete manage_event_game_path(event, 1)
    assert_match "has scores", flash[:alert]
  end
end
