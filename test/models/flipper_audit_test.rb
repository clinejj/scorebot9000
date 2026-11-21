require "test_helper"

class FlipperAuditTest < ActiveSupport::TestCase
  # Flipper's test helper swaps in an uninstrumented instance; use one wired
  # to ActiveSupport::Notifications like production.
  def instrumented_flipper
    Flipper.new(Flipper::Adapters::Memory.new, instrumenter: ActiveSupport::Notifications)
  end

  test "flag changes are recorded with the acting admin" do
    Current.session = users(:admin).sessions.create!
    assert_difference -> { AdminAuditEvent.count }, 1 do
      instrumented_flipper.enable_actor(:sms_scoring, users(:player))
    end
    event = AdminAuditEvent.order(:created_at).last
    assert_equal "flipper.enable", event.action
    assert_equal "sms_scoring", event.subject
    assert_equal users(:admin), event.user
    assert_equal users(:player).public_id, event.metadata["value"]
  end

  test "reads are not audited" do
    assert_no_difference -> { AdminAuditEvent.count } do
      instrumented_flipper.enabled?(:sms_scoring, users(:player))
    end
  end

  test "platform_admins group matches admins only" do
    Flipper.enable_group(:hosting, :platform_admins)
    assert Flipper.enabled?(:hosting, users(:admin))
    assert_not Flipper.enabled?(:hosting, users(:player))
  end
end
