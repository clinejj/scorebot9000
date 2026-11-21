require "test_helper"

class Manage::LifecyclesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  def transition(event, name)
    patch manage_event_lifecycle_path(event), params: { transition: name }
    event.reload
  end

  test "walks an event through its lifecycle" do
    event = events(:draft_party)
    assert transition(event, "publish").published?
    assert transition(event, "open_registration").registration_open?
    assert transition(event, "go_live").live?
    assert transition(event, "pause").published?
    assert transition(event, "go_live").live?
    assert transition(event, "finalize").final?
    assert event.official_snapshot.present?
    assert transition(event, "reopen").live?
    assert transition(event, "finalize").final?
    assert transition(event, "archive").archived?
    assert transition(event, "unarchive").final?
  end

  test "rejects transitions from the wrong state" do
    event = events(:clinelympics_2027)
    transition(event, "publish")
    assert event.live?
    assert_match "Can't publish", flash[:alert]
  end
end
