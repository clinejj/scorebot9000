# The event's SMS log and a simulator for rehearsing (successor to the legacy
# Texts tab). Simulated texts run the real pipeline but nothing is sent.
class Manage::SmsController < Manage::EventScopedController
  def index
    @messages = @event.sms_messages.inbound.includes(:user, :reply).recent.limit(100)
  end

  def create
    from = PhoneNumber.normalize(params[:from])
    return redirect_to(manage_event_sms_path(@event), alert: "Enter a valid mobile number.") unless from

    user = User.find_by(phone: from) || User.create!(phone: from)
    user.update!(sms_context_event: @event)
    outcome = Sms::Inbound.call(from: from, body: params[:body], simulated: true)
    redirect_to manage_event_sms_path(@event), notice: outcome.reply.present? ? "Reply: #{outcome.reply}" : "No reply (#{outcome.message&.status})."
  end
end
