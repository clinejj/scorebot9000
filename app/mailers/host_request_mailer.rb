class HostRequestMailer < ApplicationMailer
  # To every platform admin with an email.
  def submitted
    @host_request = params[:host_request]
    recipients = User.platform_admins.where.not(email: nil).map(&:email)
    return if recipients.empty?

    mail to: recipients, subject: "New host request from #{@host_request.user.display_name}"
  end

  def approved
    @host_request = params[:host_request]
    mail to: @host_request.user.email, subject: "You can host events on Scorebot 9000"
  end
end
