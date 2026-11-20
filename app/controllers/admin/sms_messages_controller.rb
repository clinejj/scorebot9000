# Platform-wide SMS log and simulator (organizers get a per-event version in
# the console). Simulated texts run the real command pipeline but aren't sent.
class Admin::SmsMessagesController < Admin::ApplicationController
  def index
    @messages = SmsMessage.includes(:event, :user, :reply).inbound.recent.limit(100)
  end

  def create
    outcome = Sms::Inbound.call(from: params[:from], body: params[:body], simulated: true)
    redirect_to admin_sms_messages_path, notice: outcome.reply.present? ? "Reply: #{outcome.reply}" : "No reply (#{outcome.message&.status})."
  end
end
