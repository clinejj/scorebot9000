require "test_helper"

class Manage::MiscControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:organizer)
    @event = events(:clinelympics_2027)
  end

  test "adjustments" do
    post manage_event_adjustments_path(@event), params: { competitor_id: teams(:wheaties).public_id, points: "2", reason: "Best uniforms" }
    adjustment = @event.adjustments.sole
    assert_equal [ teams(:wheaties), BigDecimal(2) ], [ adjustment.team, adjustment.points ]
    post manage_event_adjustments_path(@event), params: { competitor_id: teams(:wheaties).public_id, points: "0", reason: "Nothing" }
    assert flash[:alert].present?
    delete manage_event_adjustment_path(@event, adjustment)
    assert @event.adjustments.reload.empty?
  end

  test "adjustments can't target another event's competitors" do
    other = Event.create!(name: "Other", status: "live")
    other_team = other.teams.create!(name: "Ghosts")
    post manage_event_adjustments_path(@event), params: { competitor_id: other_team.public_id, points: "5", reason: "Nope" }
    assert @event.adjustments.reload.empty?
  end

  test "SMS simulator routes texts to this event" do
    Flipper.enable_actor(:sms_scoring, users(:organizer))
    post manage_event_sms_path(@event), params: { from: "909-555-0111", body: "WHO" }
    assert_match "Usain Bolt", flash[:notice]
    get manage_event_sms_path(@event)
    assert_match "WHO", response.body
  end

  test "SMS simulator routes to this event even when others are live, without changing accounts" do
    Flipper.enable_actor(:sms_scoring, users(:organizer))
    other = Event.create!(name: "Lake Day", status: "live", registration_open: true, team_mode: "none", sms_code: "LAKE27")
    Membership.create!(user: users(:organizer), resource: other, role: "owner")
    post manage_event_sms_path(@event), params: { from: "909-555-0115", body: "REGISTER Night Owls" }
    assert_match "Welcome to team Night Owls", flash[:notice]
    assert_nil users(:erin).reload.sms_context_event
  end

  test "SMS simulator doesn't create accounts for unknown numbers unless they register" do
    Flipper.enable_actor(:sms_scoring, users(:organizer))
    assert_no_difference -> { User.count } do
      post manage_event_sms_path(@event), params: { from: "909-555-0188", body: "WHO" }
    end
    assert_match "not registered", flash[:notice]
    assert_difference -> { User.count } do
      post manage_event_sms_path(@event), params: { from: "909-555-0188", body: "REGISTER Bears" }
    end
  end

  test "owners add and remove organizers" do
    assert_enqueued_emails 1 do
      post manage_event_memberships_path(@event), params: { email: "helper@example.com", role: "scorekeeper" }
    end
    assert_match "We emailed them an invite", flash[:notice]
    helper = User.find_by!(email: "helper@example.com")
    assert_equal :scorekeeper, @event.role_for(helper)
    assert_no_enqueued_emails do
      post manage_event_memberships_path(@event), params: { email: "helper@example.com", role: "organizer" }
    end
    assert_equal :organizer, @event.role_for(helper)
    delete manage_event_membership_path(@event, @event.memberships.find_by!(user: helper))
    assert_nil @event.role_for(helper)
  end

  test "organizers who aren't owners can't change organizers" do
    sign_in_as users(:carol)
    Membership.find_by!(user: users(:carol)).update!(role: "organizer")
    post manage_event_memberships_path(@event), params: { email: "x@example.com", role: "owner" }
    assert_response :not_found
  end

  test "series editing and alias names" do
    patch manage_series_path(series(:clinelympics)), params: { series: { tagline: "New tagline", alias_names: "Babe Ruth\nUsain Bolt" } }
    assert_equal "New tagline", series(:clinelympics).reload.tagline
    assert alias_pools(:classics).aliases.exists?(name: "Babe Ruth")
    patch manage_series_path(series(:clinelympics)), params: { series: { custom_domain: "evil.example.com" } }
    assert_equal "clinelympics.com", series(:clinelympics).reload.custom_domain # only platform admins can change it
  end

  test "hosts create a series and own it" do
    Flipper.enable_actor(:hosting, users(:player))
    sign_in_as users(:player)
    post manage_series_index_path, params: { series: { name: "Summer Cup" } }
    assert_equal :owner, Series.find_by!(name: "Summer Cup").role_for(users(:player))
  end
end
