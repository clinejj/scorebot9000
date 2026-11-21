class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM", "Scorebot 9000 <no-reply@scorebot9000.fly.dev>") }
  layout "mailer"
end
