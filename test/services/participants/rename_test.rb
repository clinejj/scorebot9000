require "test_helper"

module Participants
  class RenameTest < ActiveSupport::TestCase
    test "sets a chosen alias" do
      result = Rename.call(participant: participants(:alice), alias_name: "Flo Jo")
      assert result.success?
      assert_equal "Flo Jo", participants(:alice).reload.alias_name
    end

    test "rejects a taken alias" do
      result = Rename.call(participant: participants(:alice), alias_name: "simone biles")
      assert_not result.success?
    end

    test "picks a new random alias" do
      result = Rename.call(participant: participants(:alice))
      assert result.success?
      assert_not_equal "Usain Bolt", participants(:alice).reload.alias_name
      assert_equal "random", participants(:alice).alias_source
    end
  end
end
