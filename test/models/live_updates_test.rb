require "test_helper"
require "turbo/broadcastable/test_helper"

class LiveUpdatesTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper
  include ActiveJob::TestHelper

  test "a new score refreshes the event's live pages" do
    assert_turbo_stream_broadcasts events(:clinelympics_2027) do
      Scores::Submit.call(game: games(:trivia), competitor: participants(:bob), raw_value: "9", source: :sms)
      perform_enqueued_jobs
    end
    refresh = capture_turbo_stream_broadcasts(events(:clinelympics_2027)) do
      score_entries(:alice_trivia).void!
      perform_enqueued_jobs
    end
    assert refresh.all? { |stream| stream["action"] == "refresh" }
  end

  test "the legacy import doesn't broadcast" do
    assert_no_turbo_stream_broadcasts events(:clinelympics_2027) do
      LiveUpdates.suppress do
        Scores::Submit.call(game: games(:trivia), competitor: participants(:bob), raw_value: "9", source: :import)
      end
      perform_enqueued_jobs
    end
  end
end
