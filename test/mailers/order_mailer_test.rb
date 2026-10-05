require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  def mail_for(overrides = {})
    order = Order.new(**{
      heard_about_us: "Friend / Family", desired_league_name: "The Masters League", game_format: "One & Done",
      start_tournament: "The Masters", end_tournament: "The TOUR Championship", number_of_segments: "2",
      league_time_zone: "Central", projected_league_size: "34", league_password: "mysecret",
      additional_comments: "Looking forward to it", your_name: "Jane Doe", your_email: "jane@example.com",
      your_phone: "636-123-4567"
    }.merge(overrides))
    OrderMailer.order_confirmation(order)
  end

  test "goes to the requester, BCC'd to the commissioner, from the system address" do
    email = mail_for

    assert_equal [ "jane@example.com" ], email.to
    assert_equal [ ADMIN_EMAIL ], email.bcc
    assert_equal [ "System@email.ProTourFantasyGolf.com" ], email.from
    assert_equal "Request For Pro Tour Fantasy Golf League", email.subject
  end

  test "replies go to both the commissioner and the requester" do
    assert_equal [ ADMIN_EMAIL, "jane@example.com" ], mail_for.reply_to
  end

  test "is tagged for Postmark as a transactional New League Request" do
    email = mail_for

    assert_equal "outbound", email["X-PM-Message-Stream"].to_s
    assert_equal "New League Request", email["X-PM-Tag"].to_s
  end

  test "the display names on the commissioner and system addresses survive" do
    email = mail_for

    assert_includes email["Bcc"].to_s, "Fantasy Golf Commissioner"
    assert_includes email["From"].to_s, "PTFG System"
  end

  test "is HTML, greeting the requester by name and echoing back everything they entered" do
    email = mail_for

    assert_equal "text/html", email.mime_type
    body = email.body.to_s
    assert_includes body, "Dear Jane Doe,"
    [ "Email: jane@example.com", "Phone: 636-123-4567", "Desired League Name: The Masters League",
      "Game Format: One &amp; Done", "Start Tournament: The Masters", "End Tournament: The TOUR Championship",
      "Number of Segments: 2", "League Time Zone: Central", "Projected League Size: 34",
      "League Password: mysecret", "Looking forward to it" ].each do |line|
      assert_includes body, line
    end
    assert_includes body, "you heard about us via Friend / Family."
  end

  test "says None. when there are no additional comments" do
    assert_match(/Additional Comments<\/b><br>\s*None\./, mail_for(additional_comments: "").body.to_s)
  end

  test "line breaks in the additional comments survive, and markup in them is escaped" do
    body = mail_for(additional_comments: "Line one\n<script>alert(1)</script>").body.to_s

    assert_match(/Line one\s*<br \/>/, body)
    assert_no_match(/<script>/, body)
    assert_includes body, "&lt;script&gt;"
  end

  test "carries the payment instructions: PayPal, Venmo and check, with the down payment amount" do
    body = mail_for.body.to_s

    assert_includes body, "down payment of #{MIN_LEAGUE_FEE}"
    assert_includes body, "Send to: #{PAYPAL_ACCOUNT}"
    assert_includes body, "Send to: #{VENMO_ACCOUNT}"
    assert_includes body, "Make payable to: <i>#{PTFG_LLC_NAME}</i>"
    assert_includes body, "Chesterfield, MO 63005"
  end

  test "signs off with a link to the site" do
    assert_includes mail_for.body.to_s, %(<a href="#{PTFG_URL}">#{SITE_TITLE}</a> Founder)
  end
end
