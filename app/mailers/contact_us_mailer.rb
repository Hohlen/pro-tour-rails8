# Ported from legacy's ContactUsMailer. Goes to the commissioner, with the visitor's address as Reply-To.
#
# Plain text, not HTML as legacy sent it: the message should arrive exactly as the visitor typed it -- legacy's HTML
# version collapsed their line breaks and needed its own tag-stripping to be safe to display.
#
# Named contact_message rather than legacy's "message": ActionMailer::Base already has an instance method called
# #message (the underlying Mail::Message), and an action of the same name breaks delivery with a confusing
# "wrong number of arguments" error.
class ContactUsMailer < ApplicationMailer
  def contact_message(contact_us_form)
    @body = contact_us_form.body

    # Postmark: a transactional message, tagged so it's easy to find in their dashboard.
    headers["X-PM-Message-Stream"] = "outbound"
    headers["X-PM-Tag"] = "Contact Us"

    mail to: ADMIN_FULL_EMAIL_ADDRESS,
         reply_to: contact_us_form.from_email_address,
         subject: contact_us_form.subject
  end
end
