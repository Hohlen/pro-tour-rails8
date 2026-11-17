# Writes every outgoing email, in full, to the Rails log once it has been delivered. Rails 8 only logs mail at the
# debug level (and then without a recipient line at info), which production doesn't run at, so without this there's
# no record in the log of what was sent or to whom. Logged at info so it shows up in production.log.
#
# The whole message (headers plus body) goes in, so the log holds customers' names, addresses and phone numbers --
# the same data that's in the emails themselves. The To address is on the first line so a search for an address
# finds the entry; Cc and Bcc follow on their own lines, since the encoded message leaves the Bcc header out. (No
# mailer sets cc today.)
class MailLogger
  def self.delivered_email(message)
    copies = [ [ "Cc", message.cc ], [ "Bcc", message.bcc ] ]
    lines = copies.select { |_, addresses| addresses.present? }.map { |label, addresses| "  #{label}: #{addresses.join(', ')}" }
    Rails.logger.info [ "Sent email to #{Array(message.to).join(', ')}:", *lines ].join("\n") + "\n\n#{message.encoded}"
  rescue StandardError => e
    # A logging problem must never stop an order or contact email from going out.
    Rails.logger.warn "Couldn't log delivered mail: #{e.class}: #{e.message}"
  end
end

ActionMailer::Base.register_observer(MailLogger)
