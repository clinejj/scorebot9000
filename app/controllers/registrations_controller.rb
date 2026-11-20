# Joining an event on the web, and changing your team or alias.
class RegistrationsController < ApplicationController
  include EventLookup

  require_authentication
  before_action :set_event

  def new
    return redirect_to(event_path(@event), notice: "You're already registered.") if @event.participant_for(current_user)
    redirect_to(event_path(@event), alert: "Registration is closed.") unless @event.accepting_registrations?
  end

  def create
    result = Participants::Register.call(event: @event, user: current_user, team_name: params[:team_name],
      alias_name: params[:alias_name], via: :web)
    if result.success?
      redirect_to event_path(@event), notice: "You're in! You're playing as #{result.participant.alias_name}."
    else
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  def update
    participant = @event.participant_for(current_user) or return redirect_to(event_path(@event))
    error =
      if params.key?(:team_name)
        Teams::Join.call(participant: participant, team_name: params[:team_name]).error
      elsif params.key?(:alias_name)
        Participants::Rename.call(participant: participant, alias_name: params[:alias_name].presence).error
      end
    error ? redirect_to(event_path(@event), alert: error) : redirect_to(event_path(@event), notice: "Updated.")
  end
end
