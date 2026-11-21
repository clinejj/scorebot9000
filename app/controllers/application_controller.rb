class ApplicationController < ActionController::Base
  include Authentication

  authorize :user, through: :current_user
  rescue_from ActionPolicy::Unauthorized, with: :not_found

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private
    # Unauthorized pages look like missing ones, so they don't leak.
    def not_found
      raise ActionController::RoutingError, "Not Found"
    end
end
