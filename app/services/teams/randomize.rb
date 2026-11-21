module Teams
  # Builds teams from registered players.
  #
  # Randomize: shuffles everyone into `team_count` teams (or as many teams of
  # `team_size` as fit, with leftovers making some teams one bigger, e.g.
  # "teams of 2, or 3 if there's an odd number").
  # Balance (keep_existing): keeps current assignments, places unassigned
  # players, and moves the fewest people needed so sizes differ by at most one.
  class Randomize
    Result = Data.define(:teams, :error)

    def self.call(**)
      new(**).call
    end

    def initialize(event:, team_size: nil, team_count: nil, keep_existing: false, random: Random.new)
      @event = event
      @team_size = team_size
      @team_count = team_count
      @keep_existing = keep_existing
      @random = random
    end

    def call
      participants = @event.participants.to_a
      return Result.new([], "No players are registered yet.") if participants.empty?

      count = target_count(participants.size) or return Result.new([], "Enter a team size or a number of teams.")
      return Result.new([], "Can't make #{count} teams from #{participants.size} players.") if count < 1 || count > participants.size

      ApplicationRecord.transaction do
        teams = ensure_teams(count)
        @keep_existing ? balance(participants, teams) : shuffle(participants, teams)
        drop_empty_teams(teams)
        Result.new(teams.select { |team| team.participants.reload.any? }, nil)
      end
    end

    private
      def target_count(players)
        return @team_count if @team_count&.positive?
        return [ players / @team_size, 1 ].max if @team_size&.positive?

        @keep_existing && @event.teams.any? ? @event.teams.count : nil
      end

      def ensure_teams(count)
        teams = @event.teams.to_a.first(count)
        number = 1
        while teams.size < count
          name = "Team #{number}"
          teams << @event.teams.create!(name: name) unless @event.teams.find_by_name(name)
          number += 1
        end
        teams
      end

      def shuffle(participants, teams)
        participants.shuffle(random: @random).each_with_index do |participant, index|
          participant.update!(team: teams[index % teams.size])
        end
      end

      def balance(participants, teams)
        members = teams.to_h { |team| [ team, participants.select { |participant| participant.team_id == team.id } ] }
        floating = participants.reject { |participant| members.values.flatten.include?(participant) }
        floating.shuffle(random: @random).each { |participant| members[members.keys.min_by { |team| members[team].size }] << participant }
        loop do
          biggest = members.keys.max_by { |team| members[team].size }
          smallest = members.keys.min_by { |team| members[team].size }
          break if members[biggest].size - members[smallest].size <= 1

          members[smallest] << members[biggest].pop
        end
        members.each { |team, list| list.each { |participant| participant.update!(team: team) unless participant.team_id == team.id } }
      end

      def drop_empty_teams(keep)
        @event.teams.reload.each do |team|
          next if keep.include?(team) || team.participants.any? || team.score_entries.any?

          team.destroy!
        end
      end
  end
end
