class Admin::HostRequestsController < Admin::ApplicationController
  def index
    @pending = HostRequest.pending.includes(:user).order(:created_at)
    @reviewed = HostRequest.where.not(status: "pending").includes(:user, :reviewed_by_user).order(reviewed_at: :desc).limit(25)
  end

  def update
    host_request = HostRequest.find(params[:id])
    if params[:decision] == "approve"
      host_request.approve!(by: current_user, sms: params[:sms] == "1")
      redirect_to admin_host_requests_path, notice: "Approved #{host_request.user.display_name}#{" with SMS" if params[:sms] == "1"}."
    else
      host_request.decline!(by: current_user)
      redirect_to admin_host_requests_path, notice: "Declined #{host_request.user.display_name}."
    end
  end
end
