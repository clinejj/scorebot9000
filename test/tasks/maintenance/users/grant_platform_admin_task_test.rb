require "test_helper"

module Maintenance
  module Users
    class GrantPlatformAdminTaskTest < ActiveSupport::TestCase
      test "grants and revokes platform admin" do
        task = GrantPlatformAdminTask.new
        task.email = "player@example.com"
        task.process
        assert users(:player).reload.platform_admin?

        task.revoke = true
        task.process
        assert_not users(:player).reload.platform_admin?
      end
    end
  end
end
