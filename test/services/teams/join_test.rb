require "test_helper"

module Teams
  class JoinTest < ActiveSupport::TestCase
    test "moves a participant to an existing team case-insensitively" do
      result = Join.call(participant: participants(:alice), team_name: "BEARS")
      assert result.success?
      assert_equal teams(:bears), participants(:alice).reload.team
    end

    test "refuses full teams" do
      events(:clinelympics_2027).update!(max_team_size: 2)
      result = Join.call(participant: participants(:alice), team_name: "Bears")
      assert_match "full", result.error
    end

    test "won't create teams when teams are assigned" do
      events(:clinelympics_2027).update!(team_mode: "assigned")
      result = Join.call(participant: participants(:alice), team_name: "Brand New")
      assert_match "assigned", result.error
    end
  end
end
