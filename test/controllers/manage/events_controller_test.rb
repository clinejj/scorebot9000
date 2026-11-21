require "test_helper"

class Manage::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable_actor(:hosting, users(:player))
    sign_in_as users(:player)
  end

  test "hosts create standalone events and become owners" do
    post manage_events_path, params: { event: { name: "Lake Day", edition_label: "2027", time_zone: "America/New_York",
      starts_at: "2027-07-04T14:00", team_mode: "none", alias_mode: "self_chosen", scoring: { preset: "placement_points" } } }
    event = Event.find_by!(name: "Lake Day")
    assert_redirected_to manage_event_path(event)
    assert event.draft?
    assert_equal :owner, event.role_for(users(:player))
    assert_equal Time.find_zone("America/New_York").local(2027, 7, 4, 14), event.starts_at
    assert_equal "placement_points", event.scoring_config.preset
  end

  test "hosts can't create events in a series they don't manage" do
    post manage_events_path, params: { event: { name: "Sneaky", series_id: series(:clinelympics).id } }
    assert_response :unprocessable_entity
    assert_not Event.exists?(name: "Sneaky")
  end

  test "organizers update setup including scoring" do
    sign_in_as users(:organizer)
    event = events(:clinelympics_2027)
    patch manage_event_path(event), params: { event: { name: "2027 Games", accent_color: "#b91c1c",
      scoring: { preset: "weighted_medals", ranking: "dense", medal_names: "Gold, Silver", medal_points: "5, 2", placement_points: "linear", show_individual_standings: "0" } } }
    assert_redirected_to manage_event_path(event)
    event.reload
    assert_equal "2027 Games", event.name
    assert_nil event.theme["accent"] # same as the series color, so it follows the series
    config = event.scoring_config
    assert config.dense?
    assert_equal [ 5, 2 ], config.medals.map { |medal| medal["points"].to_i }
    assert_nil config.placement_points
    assert_not config.show_individual_standings?
  end

  test "the event form previews scoring with sample results, and updates it" do
    get new_manage_event_path
    assert_select "turbo-frame#scoring_preview", text: /Sample results/
    post manage_scoring_preview_path, params: { event: { team_mode: "none", scoring: { preset: "average_rank" } } }
    assert_response :success
    assert_select "turbo-frame#scoring_preview" do
      assert_select "h3", text: /Average rank/
      assert_select "td", text: /Player \d+/
    end
    post manage_scoring_preview_path, params: { event: { scoring: { preset: "olympic", ranking: "sideways" } } }
    assert_select "turbo-frame#scoring_preview", text: /won't work/
  end

  test "scoring previews for an event use its scores and need organizer access" do
    event = events(:clinelympics_2027)
    patch manage_scoring_preview_path(event_slug: event.slug), params: { event: { scoring: { preset: "weighted_medals" } } }
    assert_response :not_found

    sign_in_as users(:organizer)
    patch manage_scoring_preview_path(event_slug: event.slug), params: { event: { scoring: { preset: "weighted_medals" } } }
    assert_select "turbo-frame#scoring_preview", text: /Your event's scores so far/
    assert_select "td", text: /Bears/
  end

  test "owners can delete draft events without scores" do
    sign_in_as users(:admin)
    delete manage_event_path(events(:draft_party))
    assert_redirected_to manage_root_path
    assert_not Event.exists?(slug: "draft-party")
    delete manage_event_path(events(:clinelympics_2027))
    assert Event.exists?(slug: "clinelympics-2027")
  end
end
