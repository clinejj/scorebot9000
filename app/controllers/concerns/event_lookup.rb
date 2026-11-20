# Finds events for public pages. Draft events are visible only to people with
# a role on them (and platform admins).
module EventLookup
  extend ActiveSupport::Concern

  private
    def set_event
      @event = Event.includes(:series).find_by!(slug: params[:event_slug] || params[:slug])
      raise ActiveRecord::RecordNotFound if @event.draft? && @event.role_for(current_user).nil?

      @series = @event.series
    end
end
