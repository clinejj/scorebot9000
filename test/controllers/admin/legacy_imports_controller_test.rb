require "test_helper"

class Admin::LegacyImportsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "uploads a dump and shows its counts" do
    assert_difference -> { LegacyImport.count } do
      post admin_legacy_imports_path, params: { legacy_import: { dump_file: fixture_file_upload("legacy/dump.jsonl", "application/jsonl") } }
    end
    legacy_import = LegacyImport.last
    assert_redirected_to admin_legacy_import_path(legacy_import)
    follow_redirect!
    assert_response :success
    assert_select "td", "score"
  end

  test "starting the import enqueues the maintenance task" do
    legacy_import = LegacyImport.create!(dump_file: fixture_file_upload("legacy/dump.jsonl", "application/jsonl"), created_by_user: users(:admin))
    assert_enqueued_jobs 1 do
      post run_admin_legacy_import_path(legacy_import)
    end
    assert_redirected_to admin_legacy_import_path(legacy_import)
    assert_equal "Maintenance::Legacy::ImportTask", MaintenanceTasks::Run.last.task_name
  end

  test "the import task runs every step" do
    legacy_import = LegacyImport.create!(dump_file: fixture_file_upload("legacy/dump.jsonl", "application/jsonl"))
    task = Maintenance::Legacy::ImportTask.new
    task.legacy_import_id = legacy_import.id
    task.collection.each { |step| task.process(step) }
    assert_equal Legacy::Importer::STEPS, legacy_import.reload.report["completed_steps"]
    assert Event.exists?(legacy_event_id: 1)
  end
end
