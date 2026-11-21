# Live preview of the scoring settings on the event form: standings for the
# event's own scores, or a sample event before it has any. Nothing is saved.
class Manage::ScoringPreviewsController < Manage::BaseController
  SCORING_FIELDS = %i[preset ranking medal_names medal_points placement_points missing_scores min_games show_individual_standings].freeze

  def create
    event = find_event
    fields = params.fetch(:event, {}).fetch(:scoring, {}).permit(*SCORING_FIELDS)
    team_mode = params.dig(:event, :team_mode).presence || event&.team_mode || "self_registered"
    config = Scoring::Config.from(ScoringForm.to_config(fields), uses_teams: Event.new(team_mode: team_mode).uses_teams?)

    render partial: "manage/events/scoring_preview", locals: { preview: Scoring::Preview.call(config, event: event), event: event || Event.new }
  end

  private
    def find_event
      if params[:event_slug].present?
        Event.find_by!(slug: params[:event_slug]).tap { |event| authorize! event, to: :manage? }
      else
        require_hosting!
        nil
      end
    end
end
