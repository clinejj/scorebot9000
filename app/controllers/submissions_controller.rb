# Participants submitting their own (or their team's) scores on the web,
# mirroring the SMS commands.
class SubmissionsController < ApplicationController
  include EventLookup

  require_authentication
  before_action :set_event
  before_action :set_participant

  rate_limit to: 30, within: 1.minute, only: :create

  def create
    game = @event.games.find_by!(position: params[:game])
    result = Scores::Submit.call(game: game, competitor: @participant, raw_value: params[:value], source: :web, submitted_by: current_user)
    if result.success?
      redirect_to event_path(@event), notice: "Recorded #{result.entry.display_value} for #{game.name}."
    else
      redirect_to event_path(@event), alert: result.error
    end
  end

  def undo
    entry = Scores::Undo.call(participant: @participant)
    redirect_to event_path(@event), notice: entry ? "Removed your #{entry.game.name} score (#{entry.display_value})." : "Nothing to undo."
  end

  private
    def set_participant
      @participant = @event.participant_for(current_user) or redirect_to(event_path(@event), alert: "Join the event first.")
    end
end
