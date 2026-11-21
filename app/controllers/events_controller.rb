class EventsController < ApplicationController
  include EventLookup

  before_action :set_event

  def show
    @standings = @event.standings if @event.games.any?
    @participant = @event.participant_for(current_user)
  end

  def results
    @result = @event.standings
    @view = params[:view] == "players" && @result.individual_standings ? "players" : "teams"
    @adjustments = @event.adjustments.includes(:team, :participant).order(:created_at)
  end

  def tv
    @result = @event.standings
    render layout: "tv"
  end
end
