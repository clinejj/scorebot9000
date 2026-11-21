# Tells someone they've been added to run an event.
class MembershipMailer < ApplicationMailer
  ROLE_SUMMARIES = {
    "scorekeeper" => "enter and fix scores",
    "organizer" => "run the event: games, teams, players and scores",
    "owner" => "run the event and choose who else helps run it"
  }.freeze

  def invited
    @membership = params[:membership]
    @event = @membership.resource
    @invited_by = params[:invited_by]
    @role_summary = ROLE_SUMMARIES.fetch(@membership.role)
    @role_with_article = "#{@membership.role.match?(/\A[aeiou]/) ? "an" : "a"} #{@membership.role}"
    @inviter_name = @invited_by&.display_name || "An organizer"
    @sign_in_url = new_session_url
    @console_url = manage_event_url(@event)
    mail to: @membership.user.email, subject: "You're helping run #{@event.name} on Scorebot 9000"
  end
end
