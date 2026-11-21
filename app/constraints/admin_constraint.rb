# Route-level gate for /admin: only signed-in platform admins match. For
# everyone else the routes don't exist, so Rails answers 404.
#
# It also sets Current.session, because mounted Rack apps (Flipper UI) never
# run our controller filters, and the Flipper audit log needs to know who
# made a change.
class AdminConstraint
  def self.matches?(request)
    session_id = request.cookie_jar.signed[:session_id]
    session = Session.includes(:user).find_by(id: session_id) if session_id
    return false unless session&.user&.platform_admin?

    Current.session ||= session
    true
  end
end
