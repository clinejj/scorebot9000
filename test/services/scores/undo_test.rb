require "test_helper"

module Scores
  class UndoTest < ActiveSupport::TestCase
    test "voids the participant's latest entry" do
      later = Submit.call(game: games(:mini_golf), competitor: participants(:alice), raw_value: "40", source: :sms, submitted_by: users(:alice)).entry
      assert_equal later, Undo.call(participant: participants(:alice))
      assert later.reload.voided?
      assert_not score_entries(:alice_trivia).reload.voided?
    end

    test "voids team scores the participant submitted" do
      entry = Submit.call(game: games(:team_quiz), competitor: participants(:alice), raw_value: "9", source: :sms, submitted_by: users(:alice)).entry
      assert_equal entry, Undo.call(participant: participants(:alice))
    end

    test "returns nil when there's nothing to undo" do
      assert_nil Undo.call(participant: participants(:dave))
    end
  end
end
