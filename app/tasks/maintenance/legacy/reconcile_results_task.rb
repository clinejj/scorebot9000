module Maintenance
  module Legacy
    # Nudges imported legacy scores so recomputed results match the announced
    # (captured) results. Optional: display always uses the official snapshot.
    class ReconcileResultsTask < MaintenanceTasks::Task
      def collection
        captured = ::Legacy::CapturedResults.load_all
        Event.where(legacy_event_id: captured.keys)
      end

      def process(event)
        capture = ::Legacy::CapturedResults.load_all.fetch(event.legacy_event_id)
        outcome = ::Legacy::Reconciler.new(event, capture).reconcile!
        AdminAuditEvent.record!("legacy.reconcile", subject: event.public_id, user: nil,
          changes: outcome.changes, remaining: outcome.remaining)
      end
    end
  end
end
