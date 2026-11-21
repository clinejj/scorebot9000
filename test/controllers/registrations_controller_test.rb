require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup { @event = events(:clinelympics_2027) }

  test "joining requires sign-in" do
    get new_event_registration_path(@event)
    assert_redirected_to new_session_path
  end

  test "joins an event with a team" do
    sign_in_as users(:erin)
    get new_event_registration_path(@event)
    assert_response :success
    post event_registration_path(@event), params: { team_name: "Bears", alias_name: "" }
    assert_redirected_to event_path(@event)
    participant = @event.participant_for(users(:erin))
    assert_equal teams(:bears), participant.team
    assert_equal "web", participant.registered_via
  end

  test "switches team and renames" do
    sign_in_as users(:alice)
    patch event_registration_path(@event), params: { team_name: "Bears" }
    assert_equal teams(:bears), participants(:alice).reload.team
    patch event_registration_path(@event), params: { alias_name: "Flo Jo" }
    assert_equal "Flo Jo", participants(:alice).reload.alias_name
  end

  test "submits and undoes a score on the web" do
    sign_in_as users(:bob)
    assert_difference -> { ScoreEntry.count } do
      post event_submissions_path(@event), params: { game: 2, value: "41" }
    end
    assert_equal "Recorded 41 for Mini Golf.", flash[:notice]
    delete undo_event_submissions_path(@event)
    assert ScoreEntry.order(:created_at).last.voided?
  end

  test "web submissions follow game rules" do
    games(:mini_golf).update!(status: "locked")
    sign_in_as users(:bob)
    post event_submissions_path(@event), params: { game: 2, value: "41" }
    assert_match "isn't accepting scores", flash[:alert]
  end

  test "event page shows the join button and participant card" do
    sign_in_as users(:erin)
    get event_path(@event)
    assert_select "a", text: /Join 2027 Clinelympic Games/
    sign_in_as users(:bob)
    get event_path(@event)
    assert_match "Submit a score", response.body
  end
end
