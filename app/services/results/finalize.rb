module Results
  # Freezes an event's results: writes the official snapshot, marks games
  # final and the event final. From then on the event renders from the
  # snapshot, so scoring changes never rewrite history.
  class Finalize
    def self.call(event, by: nil)
      result = Scoring::Standings.compute(event)
      ApplicationRecord.transaction do
        event.result_snapshots.official.update_all(official: false)
        snapshot = event.result_snapshots.create!(
          computed_at: result.computed_at, official: true, source: "computed",
          scoring_config: result.config.to_h, **ResultSnapshot.columns_from(Scoring::Serializer.dump(result))
        )
        event.games.update_all(status: "final", updated_at: Time.current)
        event.update!(status: "final", finalized_at: Time.current)
        AdminAuditEvent.record!("event.finalize", subject: event.public_id, user: by)
        snapshot
      end
    end
  end
end
