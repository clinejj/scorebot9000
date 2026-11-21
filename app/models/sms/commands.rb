module Sms
  # Runs a parsed command for a user in an event, through the same services
  # the web uses, and returns the reply text.
  class Commands
    def initialize(event:, user:, command:)
      @event = event
      @user = user
      @command = command
      @participant = event.participant_for(user)
    end

    def run
      case @command.name
      when :register, :join then register
      when :score then score
      when :undo then undo
      when :who then who
      when :games then games
      when :standings then standings
      when :change_team then change_team
      when :change_name then change_name
      when :admin then admin
      else Replies.unknown
      end
    end

    private
      def require_participant
        return nil if @participant

        Replies.not_registered(@event)
      end

      def register
        if @participant
          return "You're already in #{@event.name} as #{@participant.alias_name}#{team_suffix(@participant)}."
        end

        result = Participants::Register.call(event: @event, user: @user, team_name: @command.arg(:team), via: :sms)
        return result.error unless result.success?

        participant = result.participant
        greeting = participant.team ? "Welcome to team #{participant.team.name}, #{participant.alias_name}!" : "You're registered as #{participant.alias_name}!"
        "#{greeting} Text SCORE <game #> <score> to post a score, or GAMES for the list. Good luck!"
      end

      def score
        missing = require_participant and return missing
        position = @command.arg(:game).to_s[/\A\d+\z/]&.to_i
        return "Send it like: SCORE <game #> <score>, e.g. SCORE 1 228" if position.nil? || @command.arg(:value).blank?

        game = @event.games.find_by(position: position) or return "There's no game #{position}. Text GAMES for the list."
        result = Scores::Submit.call(game: game, competitor: @participant, raw_value: @command.arg(:value), source: :sms, submitted_by: @user)
        return result.error unless result.success?

        entry = result.entry
        who = entry.team ? "team #{entry.team.name}" : @participant.alias_name
        "Got it: #{game.name} #{entry.display_value} for #{who}.#{place_note(game, entry.team || @participant)}"
      end

      def place_note(game, competitor)
        result = Scoring::Standings.compute(@event)
        game_result = result.game_results.find { |candidate| candidate.game.id == game.id }
        row = game_result&.rows&.find { |candidate| candidate.competitor.id == competitor.id || (competitor.is_a?(Participant) && candidate.competitor.id == competitor.team_id) }
        row ? " #{row.competitor.name} is #{row.place.ordinalize} in #{game.name} so far." : ""
      end

      def undo
        missing = require_participant and return missing
        entry = Scores::Undo.call(participant: @participant)
        entry ? "Removed your #{entry.game.name} score (#{entry.display_value})." : "You don't have any scores to undo."
      end

      def who
        missing = require_participant and return missing
        entries = ScoreEntry.active.joins(:game).where(games: { event_id: @event.id })
          .where("score_entries.participant_id = :participant OR score_entries.team_id = :team", participant: @participant.id, team: @participant.team_id)
          .order(:created_at).includes(:game).group_by(&:game).transform_values(&:last)
        scores = entries.sort_by { |game, _| game.position }.map { |game, entry| "#{game.name} #{entry.display_value}" }
        "You're #{@participant.alias_name}#{team_suffix(@participant)} in #{@event.name}.#{" Scores: #{scores.join(", ")}." if scores.any?}"
      end

      def games
        list = @event.games.map do |game|
          notes = []
          notes << "low wins" if game.lower_better?
          notes << "time" if game.format_time?
          notes << "team" if game.scored_by_team?
          notes << "locked" unless game.open?
          "#{game.position} #{game.name}#{" (#{notes.join(", ")})" if notes.any?}"
        end
        list.any? ? "Games: #{list.join("; ")}. Text SCORE <game #> <score>." : "No games set up yet."
      end

      def standings
        result = Scoring::Standings.compute(@event)
        top = result.standings.select(&:place).first(3).map { |row| "#{row.place} #{row.competitor.name} #{ScoreValue.trim(row.total.to_d.round(2))}" }
        return "No standings yet." if top.empty?

        mine = ""
        if @participant
          id = result.config.team_basis? ? @participant.team_id : @participant.id
          row = result.standings.find { |candidate| candidate.competitor.id == id }
          mine = " #{row.competitor.name} #{row.place ? "is #{row.place.ordinalize}" : "isn't ranked yet"}." if row
        end
        "Standings: #{top.join(", ")}.#{mine}"
      end

      def change_team
        missing = require_participant and return missing
        return "Send it like: CHANGE TEAM <team name>" if @command.arg(:team).blank?

        result = Teams::Join.call(participant: @participant, team_name: @command.arg(:team))
        result.success? ? "You're now on team #{result.team.name}." : result.error
      end

      def change_name
        missing = require_participant and return missing
        result = Participants::Rename.call(participant: @participant, alias_name: @command.arg(:alias_name))
        result.success? ? "Your new name is #{@participant.reload.alias_name}." : result.error
      end

      def admin
        policy = EventPolicy.new(@event, user: @user)
        return Replies.unknown unless policy.manage?

        case @command.arg(:action)
        when :start
          @event.update!(status: "live", registration_open: true)
          "#{@event.name} is live. Scores are open."
        when :stop
          @event.update!(status: "published")
          "#{@event.name} is paused: scores are closed. Text ADMIN START #{@event.sms_code} to reopen."
        when :final
          Results::Finalize.call(@event, by: @user)
          winner = @event.standings.standings.find { |row| row.place == 1 }
          "#{@event.name} is final.#{" Congratulations, #{winner.competitor.name}!" if winner}"
        when :lock, :unlock
          game = @event.games.find_by(position: @command.arg(:value).to_i) or return "There's no game #{@command.arg(:value)}."
          game.update!(status: @command.arg(:action) == :lock ? "locked" : "open")
          "Game #{game.position} (#{game.name}) is #{game.status}."
        end
      end

      def team_suffix(participant)
        participant.team ? " on team #{participant.team.name}" : ""
      end
  end
end
