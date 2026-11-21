class Manage::AdjustmentsController < Manage::EventScopedController
  def index
    @adjustments = @event.adjustments.includes(:team, :participant, :created_by_user).order(:created_at)
  end

  def create
    competitor = PrefixedId.locate(params[:competitor_id])
    adjustment = @event.adjustments.build(points: params[:points], reason: params[:reason], created_by_user: current_user,
      team: (competitor if competitor.is_a?(Team) && competitor.event_id == @event.id),
      participant: (competitor if competitor.is_a?(Participant) && competitor.event_id == @event.id))
    if adjustment.save
      redirect_to manage_event_adjustments_path(@event), notice: "Added #{adjustment.points.positive? ? "+" : ""}#{ScoreValue.trim(adjustment.points)} for #{adjustment.competitor.display_name}."
    else
      redirect_to manage_event_adjustments_path(@event), alert: adjustment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @event.adjustments.find(params[:id]).destroy!
    redirect_to manage_event_adjustments_path(@event), notice: "Adjustment removed."
  end
end
