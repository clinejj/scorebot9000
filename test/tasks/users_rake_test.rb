require "test_helper"
require "rake"

class UsersRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |task| task.name == "users:grant_admin" }
  end

  test "grant_admin creates and promotes a user" do
    ENV["EMAIL"] = "owner@example.com"
    assert_output(/is now a platform admin/) { Rake::Task["users:grant_admin"].execute }
    assert User.find_by(email: "owner@example.com").platform_admin?
    assert_equal "users.grant_admin", AdminAuditEvent.last.action
  ensure
    ENV.delete("EMAIL")
  end
end
