# Event lifecycle: draft -> published -> live -> final -> archived (plus
# registration open/closed, pause, reopen and unarchive).
class Manage::LifecyclesController < Manage::EventScopedController
  TRANSITIONS = {
    "publish" => { from: %w[draft], to: { status: "published" }, notice: "Published. The event page is public." },
    "unpublish" => { from: %w[published], to: { status: "draft" }, notice: "Back to draft." },
    "open_registration" => { from: %w[draft published live], to: { registration_open: true }, notice: "Registration is open." },
    "close_registration" => { from: %w[draft published live], to: { registration_open: false }, notice: "Registration is closed." },
    "go_live" => { from: %w[draft published], to: { status: "live" }, notice: "Live! Players can submit scores." },
    "pause" => { from: %w[live], to: { status: "published" }, notice: "Paused. Players can't submit scores." },
    "archive" => { from: %w[final], to: { status: "archived" }, notice: "Archived." },
    "unarchive" => { from: %w[archived], to: { status: "final" }, notice: "Unarchived." }
  }.freeze

  def update
    case params[:transition]
    when "finalize"
      return redirect_back_or_to(manage_event_path(@event), alert: "Only live or published events can be finalized.") unless @event.live? || @event.published?

      Results::Finalize.call(@event, by: current_user)
      redirect_to manage_event_path(@event), notice: "Results are final and frozen."
    when "reopen"
      return redirect_back_or_to(manage_event_path(@event), alert: "Only final events can be reopened.") unless @event.final?

      Results::Reopen.call(@event, by: current_user)
      redirect_to manage_event_path(@event), notice: "Reopened for corrections. Finalize again when you're done."
    else
      transition = TRANSITIONS.fetch(params[:transition]) { return not_found }
      if transition[:from].include?(@event.status) && @event.update(transition[:to])
        redirect_to manage_event_path(@event), notice: transition[:notice]
      else
        redirect_to manage_event_path(@event), alert: "Can't #{params[:transition].humanize.downcase} a #{@event.status} event."
      end
    end
  end
end
