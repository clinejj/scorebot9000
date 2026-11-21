require "test_helper"

class Manage::TeamsAndPlayersTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:organizer)
    @event = events(:clinelympics_2027)
  end

  test "manages teams" do
    post manage_event_teams_path(@event), params: { team: { name: "Comets" } }
    comets = @event.teams.find_by_name("Comets")
    patch manage_event_team_path(@event, comets), params: { team: { name: "Rockets", emoji: "🚀", color: "#ff0000" } }
    assert_equal "🚀 Rockets", comets.reload.display_name
    delete manage_event_team_path(@event, comets)
    assert_not Team.exists?(comets.id)
  end

  test "shuffles players into teams" do
    post randomize_manage_event_teams_path(@event), params: { team_size: 2, mode: "shuffle" }
    assert_match "Made 2 teams", flash[:notice]
    assert_equal [ 2, 2 ], @event.teams.reload.map { |team| team.participants.count }.sort
  end

  test "adds a player by phone and edits them" do
    post manage_event_participants_path(@event), params: { identifier: "909-555-0115", team_name: "Bears", alias_name: "Flo Jo" }
    participant = @event.participant_for(users(:erin))
    assert_equal [ "Flo Jo", teams(:bears), "organizer" ], [ participant.alias_name, participant.team, participant.registered_via ]

    patch manage_event_participant_path(@event, participant), params: { participant: { alias_name: "Jackie", team_id: teams(:wheaties).id } }
    assert_equal [ "Jackie", teams(:wheaties) ], [ participant.reload.alias_name, participant.team ]

    delete manage_event_participant_path(@event, participant)
    assert_not Participant.exists?(participant.id)
  end

  test "players with scores can't be removed" do
    delete manage_event_participant_path(@event, participants(:alice))
    assert_match "has scores", flash[:alert]
  end
end
