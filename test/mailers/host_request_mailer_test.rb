require "test_helper"

class HostRequestMailerTest < ActionMailer::TestCase
  test "submitted goes to platform admins" do
    host_request = users(:player).host_requests.create!(message: "Field day")
    mail = HostRequestMailer.with(host_request: host_request).submitted
    assert_equal [ "admin@example.com" ], mail.to
    assert_match "Field day", mail.body.to_s
  end

  test "approved links to the console" do
    host_request = users(:player).host_requests.create!(message: "Field day")
    mail = HostRequestMailer.with(host_request: host_request).approved
    assert_equal [ "player@example.com" ], mail.to
    assert_match "/manage/events/new", mail.body.to_s
  end
end
