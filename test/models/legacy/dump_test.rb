require "test_helper"

module Legacy
  class DumpTest < ActiveSupport::TestCase
    test "parses kinds and counts" do
      dump = Dump.parse(file_fixture("legacy/dump.jsonl").read)
      assert_equal 3, dump[:event].size
      assert_equal 11, dump.counts["score"]
      assert_equal "Usain Bolt", dump[:player].first["playerName"]
    end

    test "rejects malformed lines with a line number" do
      error = assert_raises(ArgumentError) { Dump.parse("{\"kind\":\"event\",\"properties\":{}}\nnot json\n") }
      assert_match "Line 2", error.message
    end
  end
end
