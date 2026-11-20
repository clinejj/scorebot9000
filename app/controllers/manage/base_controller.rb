# Organizer console. Every page requires sign-in; event pages also require a
# role on the event (see EventPolicy). Unauthorized requests 404.
class Manage::BaseController < ApplicationController
  require_authentication
  layout "manage"

  helper_method :can_host?

  private
    def can_host?
      current_user.platform_admin? || Flipper.enabled?(:hosting, current_user)
    end

    def require_hosting!
      not_found unless can_host?
    end
end
