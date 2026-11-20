# Base for console pages about one event (/manage/events/:event_slug/...).
class Manage::EventScopedController < Manage::BaseController
  before_action :set_event

  # Pages default to needing organizer access; score pages need scorekeeper.
  class_attribute :required_permission, default: :manage?

  private
    def set_event
      @event = Event.includes(:series).find_by!(slug: params[:event_slug])
      authorize! @event, to: required_permission
      @series = @event.series
    end
end
