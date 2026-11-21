require "test_helper"

module Participants
  class RegisterTest < ActiveSupport::TestCase
    setup { @event = events(:clinelympics_2027) }

    test "registers with a random alias from the series pool and joins a team" do
      result = Register.call(event: @event, user: users(:erin), team_name: "Wheaties", via: :sms)
      assert result.success?, result.error
      assert result.created
      participant = result.participant
      assert_equal teams(:wheaties), participant.team
      assert_equal "random", participant.alias_source
      assert_includes %w[Michael\ Phelps Mia\ Hamm], participant.alias_name
    end

    test "is idempotent" do
      result = Register.call(event: @event, user: users(:alice))
      assert result.success?
      assert_not result.created
      assert_equal participants(:alice), result.participant
    end

    test "creates new teams for self-registered team events" do
      result = Register.call(event: @event, user: users(:erin), team_name: "  Night   Owls ", via: :sms)
      assert result.success?, result.error
      assert_equal "Night Owls", result.participant.team.name
    end

    test "SMS registration needs a team name when teams are self-registered" do
      result = Register.call(event: @event, user: users(:erin), via: :sms)
      assert_not result.success?
      assert_match "REGISTER", result.error
    end

    test "rolls back when the team is full" do
      @event.update!(max_team_size: 2)
      assert_no_difference -> { Participant.count } do
        result = Register.call(event: @event, user: users(:erin), team_name: "Wheaties", via: :sms)
        assert_match "full", result.error
      end
    end

    test "respects closed registration unless forced" do
      @event.update!(registration_open: false)
      assert_not Register.call(event: @event, user: users(:erin), team_name: "Bears").success?
      assert Register.call(event: @event, user: users(:erin), team_name: "Bears", via: :organizer, force: true).success?
    end

    test "uses a chosen alias when overrides are allowed" do
      result = Register.call(event: @event, user: users(:erin), team_name: "Bears", alias_name: "Flo Jo")
      assert_equal "Flo Jo", result.participant.alias_name
      assert_equal "chosen", result.participant.alias_source
    end

    test "ignores a chosen alias when overrides are off for random-alias events" do
      @event.update!(allow_alias_override: false)
      result = Register.call(event: @event, user: users(:erin), team_name: "Bears", alias_name: "Flo Jo")
      assert_equal "random", result.participant.alias_source
    end

    test "uses real names when the event says so" do
      @event.update!(alias_mode: "real_name")
      users(:erin).update!(name: "Erin Example")
      result = Register.call(event: @event, user: users(:erin), team_name: "Bears")
      assert_equal "Erin Example", result.participant.alias_name
    end

    test "falls back to generated aliases when the pool is exhausted" do
      Alias.where(alias_pool: alias_pools(:classics)).delete_all
      result = Register.call(event: @event, user: users(:erin), team_name: "Bears")
      assert result.success?
      assert_match(/\A\w+ \w+\z/, result.participant.alias_name)
    end
  end
end
