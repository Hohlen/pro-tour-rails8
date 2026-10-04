require "test_helper"

class ContactUsMailerTest < ActionMailer::TestCase
  def mail_for(overrides = {})
    form = ContactUsForm.new(**{ from_email_address: "jane@example.com", subject: "Question about leagues",
                                 body: "How many golfers can I pick each week?" }.merge(overrides))
    ContactUsMailer.contact_message(form)
  end

  test "goes to the commissioner, from the system address, replying to the visitor" do
    email = mail_for

    assert_equal [ ADMIN_EMAIL ], email.to
    assert_equal [ "System@email.ProTourFantasyGolf.com" ], email.from
    assert_equal [ "jane@example.com" ], email.reply_to
    assert_equal "Question about leagues", email.subject
    assert_nil email.bcc
  end

  test "is plain text carrying the message exactly as typed, line breaks and all" do
    email = mail_for(body: "First line\n\nSecond line with <b>tags</b> & an ampersand")

    assert_equal "text/plain", email.mime_type
    assert_equal "First line\n\nSecond line with <b>tags</b> & an ampersand", email.body.to_s.strip
  end

  test "is tagged for Postmark as a transactional Contact Us message" do
    email = mail_for

    assert_equal "outbound", email["X-PM-Message-Stream"].to_s
    assert_equal "Contact Us", email["X-PM-Tag"].to_s
  end

  test "the display names on both addresses survive" do
    email = mail_for

    assert_includes email["To"].to_s, "Fantasy Golf Commissioner"
    assert_includes email["From"].to_s, "PTFG System"
  end
end
