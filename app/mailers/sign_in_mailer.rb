class SignInMailer < ApplicationMailer
  def code
    @sign_in_code = params[:sign_in_code]
    @code = params[:code]
    @magic_link = verify_session_url(token: @sign_in_code.magic_link_token)
    mail to: @sign_in_code.email, subject: "#{@code} is your Scorebot sign-in code"
  end
end
