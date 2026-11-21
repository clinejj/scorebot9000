require "test_helper"

# Every admin tool must 404 for anonymous visitors and regular users, and be
# reachable for platform admins (plan section 7.4). Add new admin routes here.
class AdminGateTest < ActionDispatch::IntegrationTest
  ADMIN_PATHS = %w[
    /admin
    /admin/flipper
    /admin/flipper/features
    /admin/blazer
    /admin/blazer/queries/new
    /admin/maintenance_tasks
    /admin/jobs
    /admin/legacy_imports
    /admin/legacy_imports/new
  ].freeze

  ADMIN_PATHS.each do |path|
    test "#{path} is a 404 for anonymous visitors" do
      get path
      assert_response :not_found
    end

    test "#{path} is a 404 for signed-in non-admins" do
      sign_in_as users(:player)
      get path
      assert_response :not_found
    end

    test "#{path} is reachable for platform admins" do
      sign_in_as users(:admin)
      get path
      assert_includes 200..399, response.status, "#{path} returned #{response.status}"
    end
  end

  test "an admin whose access is revoked loses it immediately" do
    sign_in_as users(:admin)
    users(:admin).revoke_platform_admin!
    get "/admin"
    assert_response :not_found
  end

  test "Blazer cannot be reached by POSTing directly either" do
    sign_in_as users(:player)
    post "/admin/blazer/queries/run", params: { statement: "SELECT 1" }
    assert_response :not_found
  end
end
