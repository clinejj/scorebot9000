# Cookie-backed sessions (adapted from the Rails 8 authentication generator).
# Pages are public by default; call `require_authentication` to protect a
# controller.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def require_authentication(**options)
      before_action :require_authentication!, **options
    end
  end

  private
    def authenticated?
      current_user.present?
    end

    def current_user
      resume_session
      Current.user
    end

    def require_authentication!
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url if request.get? || request.head?
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      reset_session
      user.sessions.create!(user_agent: request.user_agent&.first(255), ip_address: request.remote_ip).tap do |new_session|
        Current.session = new_session
        cookies.signed.permanent[:session_id] = { value: new_session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session&.destroy
      Current.session = nil
      cookies.delete(:session_id)
    end

    # Platform-admin gate for everything under /admin. Non-admins get a 404 so
    # the tools' existence isn't revealed. Also used by Blazer
    # (before_action_method), whose controllers skip our other filters.
    def require_platform_admin!
      raise ActionController::RoutingError, "Not Found" unless current_user&.platform_admin?
    end
end
