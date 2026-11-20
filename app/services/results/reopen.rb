module Results
  # Reopens a finalized event for corrections. The previous official snapshot
  # is kept (unofficial) for the record; finalizing again writes a new one.
  class Reopen
    def self.call(event, by: nil)
      ApplicationRecord.transaction do
        event.result_snapshots.official.update_all(official: false)
        event.games.where(status: "final").update_all(status: "open", updated_at: Time.current)
        event.update!(status: "live", finalized_at: nil)
        AdminAuditEvent.record!("event.reopen", subject: event.public_id, user: by)
      end
    end
  end
end
