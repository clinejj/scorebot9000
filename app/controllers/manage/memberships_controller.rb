# Co-organizers and scorekeepers for an event. Owners manage the list.
class Manage::MembershipsController < Manage::EventScopedController
  before_action -> { authorize! @event, to: :own? }, except: :index

  def index
    @memberships = @event.memberships.includes(:user).order(:created_at)
    @series_memberships = @event.series ? @event.series.memberships.includes(:user) : []
  end

  def create
    email = params[:email].to_s.strip.downcase
    return redirect_to(manage_event_memberships_path(@event), alert: "Enter a valid email.") unless email.match?(URI::MailTo::EMAIL_REGEXP)

    user = User.find_by(email: email) || User.create!(email: email)
    membership = @event.memberships.find_or_initialize_by(user: user)
    membership.role = params[:role]
    if membership.save
      if membership.previously_new_record?
        MembershipMailer.with(membership: membership, invited_by: current_user).invited.deliver_later
        notice = "#{email} is now a #{membership.role}. We emailed them an invite."
      else
        notice = "#{email} is now a #{membership.role}."
      end
      redirect_to manage_event_memberships_path(@event), notice: notice
    else
      redirect_to manage_event_memberships_path(@event), alert: membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    membership = @event.memberships.find(params[:id])
    if membership.owner? && @event.memberships.owner.count == 1 && @event.series.nil?
      redirect_to manage_event_memberships_path(@event), alert: "An event needs at least one owner."
    else
      membership.destroy!
      redirect_to manage_event_memberships_path(@event), notice: "Removed #{membership.user.display_name}."
    end
  end
end
