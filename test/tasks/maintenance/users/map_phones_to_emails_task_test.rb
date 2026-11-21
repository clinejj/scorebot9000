require "test_helper"

module Maintenance
  module Users
    class MapPhonesToEmailsTaskTest < ActiveSupport::TestCase
      test "sets pending emails for matching phones and skips conflicts" do
        task = MapPhonesToEmailsTask.new
        CSV.parse(file_fixture("phone_email_map.csv").read, headers: true).each { |row| task.process(row) }
        assert_equal "phone.only@example.com", users(:phone_only).reload.pending_email
        assert_nil users(:alice).reload.pending_email # player@example.com is taken
        assert_equal 2, AdminAuditEvent.where(action: "users.map_phone_skipped").count
      end
    end

    class MergeTaskTest < ActiveSupport::TestCase
      test "merges by prefixed id" do
        task = MergeTask.new
        task.keep_user_id = users(:player).public_id
        task.duplicate_user_id = users(:phone_only).public_id
        task.process
        assert_equal "+19095550100", users(:player).reload.phone
      end
    end
  end
end
