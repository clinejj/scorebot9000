# One upload of the legacy Datastore dump (script/legacy/dump_datastore.rb),
# imported by Maintenance::Legacy::ImportTask. The report is the
# reconciliation summary shown in /admin/legacy_imports.
class LegacyImport < ApplicationRecord
  enum :status, { uploaded: "uploaded", running: "running", succeeded: "succeeded", failed: "failed" }, validate: true

  belongs_to :created_by_user, class_name: "User", optional: true
  has_one_attached :dump_file

  validates :dump_file, presence: true, on: :create

  def dump
    @dump ||= Legacy::Dump.parse(dump_file.download)
  end

  def start!(by: nil)
    MaintenanceTasks::Runner.run(name: "Maintenance::Legacy::ImportTask", arguments: { legacy_import_id: id },
      metadata: { user_id: by&.public_id })
  end
end
