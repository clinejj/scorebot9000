# "Host an event": approved hosts go straight to creating an event; everyone
# else can request access (plan section 7.6).
class HostRequestsController < ApplicationController
  require_authentication

  def new
    return redirect_to(new_manage_event_path) if current_user.platform_admin? || Flipper.enabled?(:hosting, current_user)

    @pending = current_user.host_requests.pending.last
    @host_request = HostRequest.new
  end

  def create
    @host_request = current_user.host_requests.build(message: params.dig(:host_request, :message))
    if @host_request.save
      redirect_to host_path, notice: "Thanks! We'll let you know when you're approved."
    else
      @pending = current_user.host_requests.pending.last
      render :new, status: :unprocessable_entity
    end
  end
end
