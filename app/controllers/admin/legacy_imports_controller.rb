# Upload the legacy Datastore dump, start the import (a Maintenance Task) and
# review the reconciliation report.
class Admin::LegacyImportsController < Admin::ApplicationController
  def index
    @legacy_imports = LegacyImport.order(created_at: :desc).limit(20)
  end

  def new
    @legacy_import = LegacyImport.new
  end

  def create
    @legacy_import = LegacyImport.new(created_by_user: current_user, dump_file: params.dig(:legacy_import, :dump_file))
    if @legacy_import.save
      redirect_to admin_legacy_import_path(@legacy_import), notice: "Dump uploaded. Review the counts, then run the import."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @legacy_import = LegacyImport.find(params[:id])
    @source_counts = @legacy_import.dump.counts
  rescue ArgumentError => error
    @dump_error = error.message
  end

  def run
    legacy_import = LegacyImport.find(params[:id])
    legacy_import.start!(by: current_user)
    AdminAuditEvent.record!("legacy.import", subject: legacy_import.id)
    redirect_to admin_legacy_import_path(legacy_import), notice: "Import started. Progress is in Maintenance Tasks; refresh for the report."
  end
end
