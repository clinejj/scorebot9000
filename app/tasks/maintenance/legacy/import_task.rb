module Maintenance
  module Legacy
    # Imports an uploaded legacy dump (see /admin/legacy_imports), one step
    # per iteration so progress shows in the Maintenance Tasks UI and a
    # failed run can be resumed. Safe to re-run.
    class ImportTask < MaintenanceTasks::Task
      attribute :legacy_import_id, :string
      validates :legacy_import_id, presence: true

      after_start { legacy_import.update!(status: "running", started_at: Time.current) }
      after_complete { legacy_import.update!(status: "succeeded", finished_at: Time.current) }
      after_error { legacy_import.update!(status: "failed", finished_at: Time.current) }

      def collection
        ::Legacy::Importer::STEPS
      end

      def process(step)
        importer = ::Legacy::Importer.new(legacy_import.dump, report: ::Legacy::Report.new(legacy_import.reload.report))
        importer.run_step!(step)
        legacy_import.update!(report: importer.report.to_h.merge("completed_steps" => (legacy_import.report["completed_steps"].to_a | [ step ])))
      end

      private
        def legacy_import
          @legacy_import ||= LegacyImport.find(legacy_import_id)
        end
    end
  end
end
