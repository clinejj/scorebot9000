require "test_helper"

class Manage::ScoreSheetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:carol) # scorekeeper
    @event = events(:clinelympics_2027)
  end

  test "overview grid and per-game sheet" do
    get manage_event_score_sheets_path(@event)
    assert_response :success
    assert_match "Wheaties", response.body
    get manage_event_score_sheet_path(@event, games(:trivia))
    assert_response :success
    assert_select "input[name='scores[#{participants(:alice).public_id}]'][value='12']"
  end

  test "saves changed scores and skips unchanged ones" do
    assert_difference -> { ScoreEntry.count }, 2 do
      patch manage_event_score_sheet_path(@event, games(:trivia)), params: { scores: {
        participants(:alice).public_id => "12", participants(:bob).public_id => "18", participants(:dave).public_id => "9", participants(:carol).public_id => "" } }
    end
    assert_equal "Saved 2 scores.", flash[:notice]
    assert_equal "organizer", ScoreEntry.order(:created_at).last.source
  end

  test "team games take team scores" do
    patch manage_event_score_sheet_path(@event, games(:team_quiz)), params: { scores: { teams(:bears).public_id => "7" } }
    assert_equal teams(:bears), ScoreEntry.order(:created_at).last.team
  end

  test "reports invalid values" do
    patch manage_event_score_sheet_path(@event, games(:relay)), params: { scores: { participants(:bob).public_id => "fast" } }
    assert_match "Couldn't read", flash[:alert]
  end

  test "voids an entry" do
    delete manage_event_score_entry_path(@event, score_entries(:alice_trivia))
    assert score_entries(:alice_trivia).reload.voided?
    assert_equal users(:carol), score_entries(:alice_trivia).voided_by_user
  end
end
