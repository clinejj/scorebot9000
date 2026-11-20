# Passwordless sign-in: one "email or mobile number" field, then a 6-digit
# code (or the magic link in the email).
class SessionsController < ApplicationController
  rate_limit to: 5, within: 10.minutes, only: :create, name: "sign-in-ip",
    with: -> { redirect_to new_session_path, alert: "Too many sign-in attempts. Try again in a few minutes." }
  rate_limit to: 3, within: 10.minutes, only: :create, name: "sign-in-identifier",
    by: -> { params[:identifier].to_s.strip.downcase },
    with: -> { redirect_to new_session_path, alert: "We just sent a code there. Check your inbox or try again in a few minutes." }
  rate_limit to: 10, within: 10.minutes, only: :confirm,
    with: -> { redirect_to new_session_path, alert: "Too many attempts. Request a new code in a few minutes." }

  def new
    redirect_to root_path if authenticated?
  end

  def create
    identifier = Identifier.parse(params[:identifier])

    if identifier&.email?
      code = SignInCode.issue!(email: identifier.value, ip_address: request.remote_ip)
      SignInMailer.with(sign_in_code: code, code: code.code).code.deliver_later
      session.delete(:sign_in_phone)
      session[:sign_in_email] = identifier.value
      redirect_to verify_session_path, notice: development_code_notice(code) || "We emailed a 6-digit code to #{identifier.value}."
    elsif identifier&.phone?
      start_phone_sign_in(identifier)
    else
      flash.now[:alert] = "Enter a valid email address or mobile number."
      render :new, status: :unprocessable_entity
    end
  end

  def verify
    if params[:token].present?
      sign_in_with_magic_link(params[:token])
    elsif pending_email.blank? && pending_phone.blank?
      redirect_to new_session_path
    end
  end

  def confirm
    pending_phone.present? ? confirm_phone : confirm_email
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "Signed out."
  end

  private
    def pending_email
      session[:sign_in_email]
    end

    def pending_phone
      session[:sign_in_phone]
    end

    def confirm_email
      sign_in_code = SignInCode.latest_usable_for(pending_email) if pending_email.present?

      if sign_in_code&.verify(params[:code])
        complete_sign_in(User.from_verified_email!(sign_in_code.email))
      else
        flash.now[:alert] = sign_in_code&.usable? ? "That code didn't match. Try again." : "That code has expired. Request a new one."
        render :verify, status: :unprocessable_entity
      end
    end

    def confirm_phone
      result = PhoneVerifier.check(pending_phone, params[:code])
      if result.ok?
        complete_sign_in(User.from_verified_phone!(pending_phone))
      else
        flash.now[:alert] = result.error
        render :verify, status: :unprocessable_entity
      end
    end

    def sign_in_with_magic_link(token)
      sign_in_code = SignInCode.find_by_magic_link_token(token)
      if sign_in_code&.usable?
        sign_in_code.consume!
        complete_sign_in(User.from_verified_email!(sign_in_code.email))
      else
        redirect_to new_session_path, alert: "That sign-in link has expired. Request a new code."
      end
    end

    def complete_sign_in(user)
      return_to = after_authentication_url
      session.delete(:sign_in_email)
      session.delete(:sign_in_phone)
      start_new_session_for(user)
      redirect_to return_to, notice: "Signed in as #{user.display_name}."
    end

    def start_phone_sign_in(identifier)
      unless PhoneVerifier.available?
        flash.now[:alert] = "Signing in by text is unavailable right now. Use your email address."
        return render(:new, status: :unprocessable_entity)
      end

      result = PhoneVerifier.start(identifier.value)
      if result.ok?
        session.delete(:sign_in_email)
        session[:sign_in_phone] = identifier.value
        session[:sign_in_phone_display] = PhoneNumber.display(identifier.value)
        redirect_to verify_session_path, notice: development_phone_notice(identifier.value) || "We texted a 6-digit code to #{PhoneNumber.display(identifier.value)}."
      else
        flash.now[:alert] = result.error
        render :new, status: :unprocessable_entity
      end
    end

    def development_phone_notice(phone)
      return unless Rails.env.development? && PhoneVerifier.backend.respond_to?(:last_code_for)

      "Development: your code is #{PhoneVerifier.backend.last_code_for(phone)}."
    end

    # In development there's no mail delivery, so show the code on screen.
    def development_code_notice(code)
      "Development: your code is #{code.code}." if Rails.env.development?
    end
end
