class ApplicationMailer < ActionMailer::Base
  # From address must be on our own domain, or Yahoo and Gmail reject the message.
  default from: SYSTEM_FULL_EMAIL_ADDRESS
  layout "mailer"
end
