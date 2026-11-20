class Manage::ScoreEntriesController < Manage::EventScopedController
  self.required_permission = :score?

  def destroy
    entry = ScoreEntry.joins(:game).where(games: { event_id: @event.id }).find(params[:id])
    entry.void!(by: current_user)
    redirect_back_or_to manage_event_score_sheet_path(@event, entry.game.position), notice: "Voided #{entry.display_value} for #{entry.competitor.display_name}."
  end
end
