require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "generates a slug and SMS code" do
    event = Event.create!(name: "Summer Games", edition_label: "2028")
    assert_equal "summer-games", event.slug
    assert_equal "SUMME28", event.sms_code
    assert_equal "summer-games", event.to_param
  end

  test "keeps slugs and SMS codes unique" do
    first = Event.create!(name: "Field Day", edition_label: "2028")
    second = Event.create!(name: "Field Day", edition_label: "2028")
    assert_equal "field-day-2", second.slug
    assert_not_equal first.sms_code, second.sms_code
  end

  test "rejects reserved and malformed slugs" do
    assert_not Event.new(name: "x", slug: "admin").valid?
    assert_not Event.new(name: "x", slug: "Has Spaces").valid?
  end

  test "normalizes SMS codes" do
    event = Event.create!(name: "Lake Day", sms_code: "lake-26")
    assert_equal "LAKE26", event.sms_code
  end

  test "status scopes" do
    assert_includes Event.publicly_visible, events(:clinelympics_2021)
    assert_not_includes Event.publicly_visible, events(:draft_party)
    assert events(:clinelympics_2021).finished?
    assert events(:clinelympics_2027).accepting_registrations?
  end

  test "roles come from event and series memberships" do
    live = events(:clinelympics_2027)
    assert_equal :owner, live.role_for(users(:organizer))      # series owner
    assert_equal :scorekeeper, live.role_for(users(:carol))    # event scorekeeper
    assert_nil live.role_for(users(:player))
    assert_equal :owner, live.role_for(users(:admin))          # platform admin
    assert_nil events(:draft_party).role_for(users(:organizer))
    assert_includes live.owners, users(:organizer)
  end

  test "accent color falls back to the series theme" do
    assert_equal "#b91c1c", events(:clinelympics_2027).accent_color
    assert_equal "#ffffff", events(:clinelympics_2027).accent_ink_color
  end

  test "validates theme colors" do
    event = events(:draft_party)
    event.accent_color = "red"
    assert_not event.valid?
  end

  test "effective alias pool falls back through series to platform" do
    assert_equal alias_pools(:classics), events(:clinelympics_2027).effective_alias_pool
    assert_equal alias_pools(:platform), events(:draft_party).effective_alias_pool
  end

  test "has a prefixed id" do
    assert events(:clinelympics_2027).public_id.start_with?("evt_")
    assert_equal events(:clinelympics_2027), Event.find(events(:clinelympics_2027).public_id)
  end
end
