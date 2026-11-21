class Manage::ParticipantsController < Manage::EventScopedController
  def index
    @participants = @event.participants.includes(:team, :user).order(Arel.sql("lower(alias_name)"))
  end

  # Adds a player by email or mobile number (creating their account if
  # needed), even when registration is closed.
  def create
    identifier = Identifier.parse(params[:identifier])
    return redirect_to(manage_event_participants_path(@event), alert: "Enter a valid email or mobile number.") unless identifier

    user = identifier.email? ? User.find_by(email: identifier.value) || User.create!(email: identifier.value) : User.find_by(phone: identifier.value) || User.create!(phone: identifier.value)
    result = Participants::Register.call(event: @event, user: user, team_name: params[:team_name], alias_name: params[:alias_name], via: :organizer, force: true)
    if result.success?
      notice = result.created ? "Added #{result.participant.alias_name}." : "#{result.participant.alias_name} is already registered."
      redirect_to manage_event_participants_path(@event), notice: notice
    else
      redirect_to manage_event_participants_path(@event), alert: result.error
    end
  end

  def update
    participant = @event.participants.find(params[:id])
    attributes = params.expect(participant: [ :alias_name, :team_id ])
    attributes[:alias_source] = "chosen" if attributes[:alias_name].present? && attributes[:alias_name] != participant.alias_name
    attributes[:team_id] = nil if attributes.key?(:team_id) && attributes[:team_id].blank?
    if participant.update(attributes)
      redirect_to manage_event_participants_path(@event), notice: "Saved #{participant.alias_name}."
    else
      redirect_to manage_event_participants_path(@event), alert: participant.errors.full_messages.to_sentence
    end
  end

  def destroy
    participant = @event.participants.find(params[:id])
    if participant.score_entries.exists?
      redirect_to manage_event_participants_path(@event), alert: "#{participant.alias_name} has scores; void them first."
    else
      participant.destroy!
      redirect_to manage_event_participants_path(@event), notice: "Removed #{participant.alias_name}."
    end
  end
end
