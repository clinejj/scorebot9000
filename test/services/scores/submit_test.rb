require "test_helper"

module Scores
  class SubmitTest < ActiveSupport::TestCase
    test "records an individual score" do
      result = Submit.call(game: games(:trivia), competitor: participants(:bob), raw_value: "20", source: :sms, submitted_by: users(:bob))
      assert result.success?, result.error
      assert_equal 20, result.entry.value
      assert_equal participants(:bob), result.entry.participant
    end

    test "records a team-game score for the player's team" do
      result = Submit.call(game: games(:team_quiz), competitor: participants(:bob), raw_value: "7", source: :sms)
      assert result.success?, result.error
      assert_equal teams(:wheaties), result.entry.team
      assert_nil result.entry.participant
    end

    test "parses times" do
      result = Submit.call(game: games(:relay), competitor: participants(:bob), raw_value: "1:23.4", source: :web)
      assert_equal BigDecimal("83.4"), result.entry.value
    end

    test "explains unreadable values" do
      result = Submit.call(game: games(:relay), competitor: participants(:bob), raw_value: "fast", source: :sms)
      assert_match "1:23.45", result.error
    end

    test "players can't submit to locked games but organizers can" do
      games(:trivia).update!(status: "locked")
      assert_not Submit.call(game: games(:trivia), competitor: participants(:bob), raw_value: "1", source: :sms).success?
      assert Submit.call(game: games(:trivia), competitor: participants(:bob), raw_value: "1", source: :organizer, as_organizer: true).success?
    end

    test "nobody can submit once the event is final" do
      result = Submit.call(game: games(:legacy_trivia), competitor: teams(:wheaties), raw_value: "1", source: :organizer, as_organizer: true)
      assert_match "final", result.error
    end

    test "a player without a team can't score team games" do
      participants(:bob).update!(team: nil)
      result = Submit.call(game: games(:team_quiz), competitor: participants(:bob), raw_value: "7", source: :sms)
      assert_match "team", result.error
    end
  end
end
