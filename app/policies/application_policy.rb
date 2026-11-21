# Base class for authorization policies (Action Policy). Per-record roles
# come from memberships; platform admins can do everything.
class ApplicationPolicy < ActionPolicy::Base
  authorize :user, allow_nil: true

  private
    def platform_admin?
      user&.platform_admin?
    end
end
