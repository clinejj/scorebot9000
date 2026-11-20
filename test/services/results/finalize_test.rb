require "test_helper"

module Results
  class FinalizeTest < ActiveSupport::TestCase
    setup { @event = events(:clinelympics_2027) }

    test "finalizing freezes results in an official snapshot" do
      snapshot = Finalize.call(@event, by: users(:organizer))
      assert snapshot.official?
      assert @event.reload.final?
      assert @event.finalized_at.present?
      assert @event.games.all?(&:final?)

      # Later changes don't affect the frozen results.
      @event.update_columns(status: "live")
      Scores::Submit.call(game: games(:trivia), competitor: participants(:bob), raw_value: "99", source: :organizer, as_organizer: true)
      @event.update_columns(status: "final")
      assert_equal "Bears", @event.reload.standings.standings.first.competitor.name
    end

    test "reopening keeps the old snapshot unofficial and finalizing again replaces it" do
      first = Finalize.call(@event)
      Reopen.call(@event)
      assert @event.reload.live?
      assert_not first.reload.official?
      second = Finalize.call(@event.reload)
      assert second.official?
      assert_equal 1, @event.result_snapshots.official.count
      assert_equal 2, @event.result_snapshots.count
    end
  end
end
