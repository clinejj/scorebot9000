require "test_helper"

module Legacy
  class ReconcilerTest < ActiveSupport::TestCase
    test "nudges scores so recomputed results match what was announced" do
      mismatch = CapturedResults.load_all(Rails.root.join("test/fixtures/files/legacy/captured_mismatch"))
      Importer.new(Dump.parse(file_fixture("legacy/dump.jsonl").read), captured: mismatch).run!
      event = Event.find_by!(legacy_event_id: 1)

      outcome = Reconciler.new(event, mismatch.fetch(1)).reconcile!
      assert_equal 1, outcome.changes.size
      assert_match "Trivia / Bears", outcome.changes.first
      entry = ScoreEntry.from_reconciliation.sole
      assert_match "announced Bears total was 12", entry.note
      assert_equal 1, ScoreEntry.where.not(voided_at: nil).count
      assert_empty outcome.remaining.grep(/Trivia/)
    end
  end
end
