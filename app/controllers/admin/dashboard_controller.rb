class Admin::DashboardController < Admin::ApplicationController
  def show
    @user_count = User.count
    @admin_count = User.platform_admins.count
    @pending_host_requests = HostRequest.pending.count
    @recent_audit_events = AdminAuditEvent.includes(:user).order(created_at: :desc).limit(20)
  end
end
