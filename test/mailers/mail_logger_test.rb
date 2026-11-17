require "test_helper"

class MailLoggerTest < ActiveSupport::TestCase
  test "a delivered email is logged in full, with its recipient, subject and body" do
    form = ContactUsForm.new(from_email_address: "jane@example.com", subject: "Question about pricing", body: "Hello there")

    log = capture_log { ContactUsMailer.contact_message(form).deliver_now }

    assert_match(/\ASent email to #{Regexp.escape(ADMIN_EMAIL)}:\n\n/, log)
    assert_match(/^Subject: Question about pricing/, log)
    assert_match(/^Reply-To: jane@example\.com/, log)
    assert_match(/Hello there/, log)
  end

  test "a bcc is listed under the to address, as an order confirmation has" do
    message = Mail.new(to: "customer@example.com", bcc: ADMIN_EMAIL, subject: "Request", body: "x")

    log = capture_log { MailLogger.delivered_email(message) }

    assert_match(/\ASent email to customer@example\.com:\n  Bcc: #{Regexp.escape(ADMIN_EMAIL)}\n\n/, log)
  end

  test "cc and bcc are each listed on their own line under the to address" do
    message = Mail.new(to: "a@example.com", cc: "b@example.com", bcc: "c@example.com", subject: "Hi", body: "x")

    log = capture_log { MailLogger.delivered_email(message) }

    assert_match(/\ASent email to a@example\.com:\n  Cc: b@example\.com\n  Bcc: c@example\.com\n\n/, log)
  end

  test "only the first line is written when there is no cc or bcc" do
    message = Mail.new(to: "a@example.com", subject: "Hi", body: "x")

    log = capture_log { MailLogger.delivered_email(message) }

    assert_match(/\ASent email to a@example\.com:\n\n/, log)
  end

  test "a problem logging the email is swallowed so delivery still succeeds" do
    log = capture_log { MailLogger.delivered_email(Object.new) }

    assert_match(/Couldn't log delivered mail: NoMethodError/, log)
  end

  private

  def capture_log
    io = StringIO.new
    original = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io, level: :info) # production logs at info
    yield
    io.string
  ensure
    Rails.logger = original
  end
end
