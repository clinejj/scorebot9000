require "test_helper"

module Teams
  class RandomizeTest < ActiveSupport::TestCase
    setup do
      @event = events(:clinelympics_2027)
      3.times { |i| Participants::Register.call(event: @event, user: User.create!(phone: "+1909555020#{i}"), via: :organizer, force: true) }
    end

    test "teams of 2 with leftovers joining existing teams" do
      result = Randomize.call(event: @event, team_size: 2, random: Random.new(1))
      assert_nil result.error
      sizes = result.teams.map { |team| team.participants.count }.sort
      assert_equal [ 2, 2, 3 ], sizes # 7 players: two 2s and a 3
    end

    test "a fixed number of teams" do
      result = Randomize.call(event: @event, team_count: 2, random: Random.new(1))
      assert_equal [ 3, 4 ], result.teams.map { |team| team.participants.count }.sort
    end

    test "balance keeps existing assignments where possible" do
      result = Randomize.call(event: @event, keep_existing: true, random: Random.new(1))
      assert_equal [ 3, 4 ], result.teams.map { |team| team.participants.count }.sort
      assert_equal teams(:wheaties), participants(:alice).reload.team
    end

    test "explains impossible requests" do
      assert_match "Can't make", Randomize.call(event: @event, team_count: 50).error
      assert_match "No players", Randomize.call(event: Event.create!(name: "Empty"), team_size: 2).error
    end
  end
end
