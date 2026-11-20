class SeriesPolicy < ApplicationPolicy
  def manage?
    at_least?(:organizer)
  end

  def own?
    at_least?(:owner)
  end

  private
    def at_least?(minimum)
      Membership.role_at_least?(record.role_for(user), minimum)
    end
end
