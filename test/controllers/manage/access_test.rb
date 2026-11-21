require "test_helper"

class Manage::AccessTest < ActionDispatch::IntegrationTest
  setup { @event = events(:clinelympics_2027) }

  test "the console requires sign-in" do
    get manage_root_path
    assert_redirected_to new_session_path
  end

  test "series owners see and manage their events" do
    sign_in_as users(:organizer)
    get manage_root_path
    assert_response :success
    assert_match "2027 Clinelympic Games", response.body
    %w[manage_event_path edit_manage_event_path manage_event_games_path manage_event_teams_path manage_event_participants_path
       manage_event_score_sheets_path manage_event_adjustments_path manage_event_sms_path manage_event_memberships_path].each do |helper|
      get send(helper, @event)
      assert_response :success, "#{helper} should be reachable"
    end
  end

  test "scorekeepers can only reach score pages" do
    sign_in_as users(:carol)
    get manage_event_score_sheets_path(@event)
    assert_response :success
    get manage_event_score_sheet_path(@event, games(:trivia))
    assert_response :success
    get edit_manage_event_path(@event)
    assert_response :not_found
    get manage_event_games_path(@event)
    assert_response :not_found
  end

  test "people without a role get 404s" do
    sign_in_as users(:player)
    get manage_event_path(@event)
    assert_response :not_found
    get manage_event_score_sheets_path(@event)
    assert_response :not_found
  end

  test "creating events and series requires the hosting flag" do
    sign_in_as users(:player)
    get new_manage_event_path
    assert_response :not_found
    get new_manage_series_path
    assert_response :not_found
    Flipper.enable_actor(:hosting, users(:player))
    get new_manage_event_path
    assert_response :success
  end
end
