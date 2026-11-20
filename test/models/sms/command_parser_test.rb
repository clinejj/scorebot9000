require "test_helper"

module Sms
  class CommandParserTest < ActiveSupport::TestCase
    def parse(text) = CommandParser.parse(text)

    test "legacy commands keep working" do
      assert_equal [ :register, { team: "WHEATIES" } ], parse("REGISTER WHEATIES").then { |c| [ c.name, c.args ] }
      assert_equal [ :score, { game: "1", value: "228" } ], parse("SCORE 1 228").then { |c| [ c.name, c.args ] }
      assert_equal :who, parse("who").name
      assert_equal [ :change_team, { team: "Night Owls" } ], parse("change team Night Owls").then { |c| [ c.name, c.args ] }
      assert_equal [ :change_name, { alias_name: nil } ], parse("CHANGE NAME").then { |c| [ c.name, c.args ] }
    end

    test "is forgiving about case, spacing and shortcuts" do
      assert_equal [ :score, { game: "3", value: "1:23.45" } ], parse("  s   3   1:23.45 ").then { |c| [ c.name, c.args ] }
      assert_equal :standings, parse("Rank").name
      assert_equal :commands, parse("?").name
      assert_equal :register, parse("register").name
      assert_nil parse("register").arg(:team)
    end

    test "join takes a code and optional team" do
      command = parse("join cline27 Bears")
      assert_equal :join, command.name
      assert_equal "CLINE27", command.arg(:code)
      assert_equal "Bears", command.arg(:team)
    end

    test "admin commands" do
      assert_equal({ action: :start, value: "CLINE27" }, parse("ADMIN START CLINE27").args)
      assert_equal({ action: :lock, value: "3" }, parse("admin lock 3").args)
      assert_equal :unknown, parse("ADMIN").name
      assert_equal :unknown, parse("ADMIN DANCE").name
    end

    test "carrier keywords are recognized only as the whole message" do
      %w[STOP stop HELP Start].each { |word| assert_equal :carrier_keyword, parse(word).name }
      assert_equal :admin, parse("ADMIN STOP").name
    end

    test "unknown, empty and malformed input never raise" do
      assert_equal :unknown, parse("hello there").name
      assert_equal :empty, parse("   ").name
      assert_equal :unknown, parse("CHANGE").name
      assert_equal :score, parse("SCORE").name
    end
  end
end
