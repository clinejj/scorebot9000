class Manage::EventsController < Manage::BaseController
  before_action :require_hosting!, only: %i[new create]
  before_action :set_event, only: %i[show edit update destroy]

  def show
    @checklist = checklist
  end

  def new
    @event = Event.new(series_id: params[:series_id], time_zone: "America/Los_Angeles", team_mode: "self_registered", alias_mode: "random")
  end

  def create
    @event = Event.new(event_params.merge(created_by_user: current_user, status: "draft"))
    if allowed_series?(@event.series) && @event.save
      Membership.create!(user: current_user, resource: @event, role: "owner") unless @event.role_for(current_user) == :owner
      redirect_to manage_event_path(@event), notice: "Event created. Add games next."
    else
      @event.errors.add(:series, "isn't one you manage") unless allowed_series?(@event.series)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if event_params.key?(:series_id) && event_params[:series_id].to_s != @event.series_id.to_s &&
        !allowed_series?(Series.find_by(id: event_params[:series_id]))
      @event.errors.add(:series, "isn't one you manage")
      return render(:edit, status: :unprocessable_entity)
    end

    if @event.update(event_params)
      redirect_to manage_event_path(@event), notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! @event, to: :own?
    if @event.draft? && @event.score_entries.none?
      @event.destroy!
      redirect_to manage_root_path, notice: "Deleted #{@event.name}."
    else
      redirect_to manage_event_path(@event), alert: "Only draft events without scores can be deleted. Archive it instead."
    end
  end

  private
    def set_event
      @event = Event.find_by!(slug: params[:slug])
      authorize! @event, to: :manage?
      @series = @event.series
    end

    def allowed_series?(series)
      series.nil? || SeriesPolicy.new(series, user: current_user).manage?
    end

    def event_params
      permitted = params.expect(event: [
        :name, :series_id, :slug, :edition_label, :starts_at, :ends_at, :time_zone, :location_text, :online_url,
        :description, :rules, :schedule, :hero, :accent_color, :sms_code, :team_mode, :max_team_size,
        :alias_mode, :allow_alias_override, :alias_pool_id,
        scoring: [ :preset, :ranking, :medal_names, :medal_points, :placement_points, :missing_scores, :min_games, :show_individual_standings ]
      ])
      permitted[:scoring] = ScoringForm.to_config(permitted[:scoring]) if permitted.key?(:scoring)
      permitted[:max_team_size] = nil if permitted[:max_team_size].blank? && permitted.key?(:max_team_size)
      # Times are entered in the event's own time zone.
      zone = Time.find_zone(permitted[:time_zone].presence || @event&.time_zone || "UTC")
      %i[starts_at ends_at].each do |key|
        permitted[key] = zone.parse(permitted[key]) if permitted[key].present? && zone
      end
      # Follow the series color unless the organizer picked a different one.
      series = Series.find_by(id: permitted.fetch(:series_id, @event&.series_id))
      permitted[:accent_color] = nil if permitted[:accent_color].present? && permitted[:accent_color].casecmp?(series&.accent_color.to_s)
      permitted
    end

    def checklist
      [
        [ "Add games", @event.games.any?, manage_event_games_path(@event) ],
        [ "Publish the event page", !@event.draft?, nil ],
        [ "Open registration", @event.registration_open? || @event.participants.any?, nil ],
        [ "Players registered", @event.participants.any?, manage_event_participants_path(@event) ],
        [ "Go live for scoring", @event.live? || @event.finished?, nil ],
        [ "Finalize results", @event.finished?, nil ]
      ]
    end
end
