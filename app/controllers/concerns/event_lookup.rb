# Finds events for public pages. Draft events are visible only to people with
# a role on them (and platform admins).
module EventLookup
  extend ActiveSupport::Concern

  private
    def set_event
      @event = Event.includes(:series).find_by!(slug: params[:event_slug] || params[:slug])
      authorize! @event, to: :show?

      @series = @event.series
    end
end
