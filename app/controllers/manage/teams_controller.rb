class Manage::TeamsController < Manage::EventScopedController
  def index
    @teams = @event.teams.includes(:participants)
    @unassigned = @event.participants.where(team_id: nil).order(:alias_name)
    @team = Team.new
  end

  def create
    @team = @event.teams.build(team_params)
    if @team.save
      redirect_to manage_event_teams_path(@event), notice: "Added #{@team.name}."
    else
      redirect_to manage_event_teams_path(@event), alert: @team.errors.full_messages.to_sentence
    end
  end

  def update
    team = @event.teams.find(params[:id])
    if team.update(team_params)
      redirect_to manage_event_teams_path(@event), notice: "Saved #{team.name}."
    else
      redirect_to manage_event_teams_path(@event), alert: team.errors.full_messages.to_sentence
    end
  end

  def destroy
    team = @event.teams.find(params[:id])
    if team.score_entries.exists?
      redirect_to manage_event_teams_path(@event), alert: "#{team.name} has team scores; rename it instead."
    else
      team.destroy!
      redirect_to manage_event_teams_path(@event), notice: "Deleted #{team.name}. Its players are unassigned."
    end
  end

  def randomize
    result = Teams::Randomize.call(event: @event, team_size: params[:team_size].presence&.to_i,
      team_count: params[:team_count].presence&.to_i, keep_existing: params[:mode] == "balance")
    if result.error
      redirect_to manage_event_teams_path(@event), alert: result.error
    else
      redirect_to manage_event_teams_path(@event), notice: "Made #{result.teams.size} teams: #{result.teams.map { |team| "#{team.name} (#{team.participants.count})" }.join(", ")}."
    end
  end

  private
    def team_params
      params.expect(team: [ :name, :color, :emoji ])
    end
end
