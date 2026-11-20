class EventPolicy < ApplicationPolicy
  def show?
    !record.draft? || role.present?
  end

  # Enter and void scores.
  def score?
    at_least?(:scorekeeper)
  end

  # Edit content, games, teams, participants; run the event.
  def manage?
    at_least?(:organizer)
  end

  # Delete the event, manage organizers.
  def own?
    at_least?(:owner)
  end

  private
    def role
      @role ||= record.role_for(user)
    end

    def at_least?(minimum)
      Membership.role_at_least?(role, minimum)
    end
end
