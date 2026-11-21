# Adds an email or phone to the signed-in account after verifying a code.
# If the identifier belongs to another account, verifying it proves the
# same person owns both, so the accounts are merged (plan section 7.2).
class IdentifiersController < ApplicationController
  require_authentication

  rate_limit to: 5, within: 10.minutes, only: :create,
    with: -> { redirect_to account_path, alert: "Too many attempts. Try again in a few minutes." }
  rate_limit to: 10, within: 10.minutes, only: :confirm,
    with: -> { redirect_to account_path, alert: "Too many attempts. Try again in a few minutes." }

  def new
    @kind = params[:kind] == "phone" ? "phone" : "email"
  end

  def create
    identifier = Identifier.parse(params[:identifier])
    @kind = params[:kind] == "phone" ? "phone" : "email"

    if identifier.nil? || identifier.kind.to_s != @kind
      flash.now[:alert] = @kind == "phone" ? "Enter a valid mobile number." : "Enter a valid email address."
      return render(:new, status: :unprocessable_entity)
    end

    if identifier.email?
      code = SignInCode.issue!(email: identifier.value, ip_address: request.remote_ip)
      SignInMailer.with(sign_in_code: code, code: code.code).code.deliver_later
    else
      return redirect_to(account_path, alert: "Texting codes is unavailable right now.") unless PhoneVerifier.available?

      result = PhoneVerifier.start(identifier.value)
      unless result.ok?
        flash.now[:alert] = result.error
        return render(:new, status: :unprocessable_entity)
      end
    end
    session[:pending_identifier] = { "kind" => identifier.kind.to_s, "value" => identifier.value }
    redirect_to verify_identifiers_path, notice: "We sent a 6-digit code to #{identifier.email? ? identifier.value : PhoneNumber.display(identifier.value)}."
  end

  def verify
    redirect_to account_path unless pending
  end

  def confirm
    return redirect_to(account_path) unless pending

    if verified?
      kind = pending["kind"]
      attach!
      session.delete(:pending_identifier)
      redirect_to account_path, notice: "#{kind == "email" ? "Email" : "Phone"} added. You can sign in with it now."
    else
      flash.now[:alert] = "That code didn't match or has expired."
      render :verify, status: :unprocessable_entity
    end
  rescue Users::Merge::Conflict => error
    session.delete(:pending_identifier)
    redirect_to account_path, alert: "Couldn't combine accounts: #{error.message}."
  end

  private
    def pending
      session[:pending_identifier]
    end

    def verified?
      if pending["kind"] == "email"
        SignInCode.latest_usable_for(pending["value"])&.verify(params[:code])
      else
        PhoneVerifier.check(pending["value"], params[:code]).ok?
      end
    end

    def attach!
      attribute = pending["kind"] == "email" ? :email : :phone
      value = pending["value"]
      other = User.where.not(id: current_user.id).find_by(attribute => value)
      Users::Merge.call(keep: current_user, duplicate: other, by: current_user) if other
      current_user.reload.update!(attribute => value, "#{attribute}_verified_at" => Time.current)
      current_user.update!(pending_email: nil) if attribute == :email && current_user.pending_email == value
    end
end
