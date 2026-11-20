require "test_helper"

class SeriesStatsTest < ActiveSupport::TestCase
  test "champions, all-time medals and records come from official results" do
    event = events(:clinelympics_2027)
    Results::Finalize.call(event)
    stats = SeriesStats.new(series(:clinelympics))

    assert_equal [ [ event, [ "Bears" ] ] ], stats.champions.map { |champion| [ champion.event, champion.names ] }
    # Bears won Trivia gold; both Bears members get the medal.
    rows = stats.all_time_medals
    assert_equal [ "Simone Biles", "Turbo Otter" ], rows.select { |row| row.medal_counts.first == 1 }.map(&:name).sort
    assert_equal [], stats.records # each game was only played once
  end
end
