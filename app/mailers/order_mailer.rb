# Ported from legacy's OrderMailer. The HTML confirmation emailed to whoever asked about starting a league, BCC'd
# to the commissioner, with replies going to both.
class OrderMailer < ApplicationMailer
  # Named order_confirmation rather than legacy's "order" for the same reason ContactUsMailer's is contact_message:
  # keeping clear of ActionMailer::Base's own method names.
  def order_confirmation(order)
    @order = order

    # Postmark: a transactional message, tagged so it's easy to find in their dashboard.
    headers["X-PM-Message-Stream"] = "outbound"
    headers["X-PM-Tag"] = "New League Request"

    mail to: order.your_email,
         bcc: ADMIN_FULL_EMAIL_ADDRESS,
         reply_to: [ ADMIN_FULL_EMAIL_ADDRESS, order.your_email ],
         subject: "Request For #{SITE_TITLE} League"
  end
end
