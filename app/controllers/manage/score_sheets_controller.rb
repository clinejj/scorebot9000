# Score entry for organizers and scorekeepers: an overview grid, and a
# per-game sheet where you can tab through competitors and save in one go.
class Manage::ScoreSheetsController < Manage::EventScopedController
  self.required_permission = :score?

  def index
    @result = Scoring::Standings.compute(@event)
    @games = @event.games.to_a
    @competitors = @result.config.team_basis? ? @event.teams.to_a : @event.participants.order(:alias_name).to_a
  end

  def show
    @game = @event.games.find_by!(position: params[:position])
    @competitors = competitors_for(@game)
    @current = current_values(@game)
    @recent = @game.score_entries.includes(:participant, :team, :submitted_by_user).order(created_at: :desc).limit(25)
  end

  def update
    game = @event.games.find_by!(position: params[:position])
    current = current_values(game)
    saved = 0
    errors = []
    params.fetch(:scores, {}).each do |public_id, raw|
      next if raw.to_s.strip.empty?

      competitor = game.scored_by_team? ? @event.teams.find(public_id) : @event.participants.find(public_id)
      next if current[competitor.id] && game.parse_value(raw) == current[competitor.id]

      result = Scores::Submit.call(game: game, competitor: competitor, raw_value: raw, source: :organizer, submitted_by: current_user, as_organizer: true)
      result.success? ? saved += 1 : errors << "#{competitor.display_name}: #{result.error}"
    end
    flash[:alert] = errors.to_sentence if errors.any?
    redirect_to manage_event_score_sheet_path(@event, game.position), notice: "Saved #{saved} #{"score".pluralize(saved)}."
  end

  private
    def competitors_for(game)
      game.scored_by_team? ? @event.teams.to_a : @event.participants.includes(:team).order(Arel.sql("lower(alias_name)")).to_a
    end

    # competitor id => latest active value (what the sheet shows)
    def current_values(game)
      key = game.scored_by_team? ? :team_id : :participant_id
      game.score_entries.active.order(:created_at).pluck(key, :value).to_h
    end
end
