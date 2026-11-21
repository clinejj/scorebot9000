require "test_helper"

class EventPolicyTest < ActiveSupport::TestCase
  def policy(user, event = events(:clinelympics_2027)) = EventPolicy.new(event, user: user)

  test "series owners manage events in the series" do
    assert policy(users(:organizer)).manage?
    assert policy(users(:organizer)).own?
  end

  test "scorekeepers can score but not manage" do
    assert policy(users(:carol)).score?
    assert_not policy(users(:carol)).manage?
  end

  test "regular users can only view public events" do
    assert policy(users(:player)).show?
    assert_not policy(users(:player)).score?
    assert_not policy(users(:player), events(:draft_party)).show?
    assert_not policy(nil, events(:draft_party)).show?
  end

  test "platform admins can do everything" do
    assert policy(users(:admin), events(:draft_party)).own?
  end

  test "series policy" do
    assert SeriesPolicy.new(series(:clinelympics), user: users(:organizer)).own?
    assert_not SeriesPolicy.new(series(:clinelympics), user: users(:carol)).manage?
  end
end
