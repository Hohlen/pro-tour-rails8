require "test_helper"

# Ported from legacy's test/functional/order_now_controller_test.rb, plus the hardening the port added.
class OrderNowTest < ActionDispatch::IntegrationTest
  def valid_params(overrides = {})
    { heard_about_us: "Google", desired_league_name: "The Masters League", game_format: "One & Done",
      start_tournament: "The Masters", end_tournament: "The Open Championship", number_of_segments: "2",
      league_time_zone: "Central", projected_league_size: "20", league_password: "mysecret",
      additional_comments: "Looking forward to it", your_name: "John Doe", your_email: "john@example.com",
      your_phone: "314-605-9995" }.merge(overrides)
  end

  # Sends the form with Google's verdict stubbed, so these never reach Google. Any other keyword overrides a form
  # field (submit(your_name: "")); verified: is Google's answer, recaptcha_response: what the widget put in the form
  # (nil for none).
  def submit(verified: true, recaptcha_response: "stubbed-token", **field_overrides)
    params = { order: valid_params(field_overrides) }
    params["g-recaptcha-response"] = recaptcha_response if recaptcha_response
    stub_class_method(GoogleRecaptchaVerifier, :verify, verified) { post order_now_path, params: params }
  end

  # --- the blank form ---

  test "new renders the form with its two panels and no error state" do
    get order_now_path

    assert_response :success
    assert_select "title", /\AOrder Now \| Pro Tour Fantasy Golf \d{4}\z/
    assert_select "h2#pageTitle", "Order Now"
    assert_select "form.ctForm[action='/order_now'][method='post']"
    assert_select ".card-header h4.card-title", text: "League Details"
    assert_select ".card-header h4.card-title", text: "Contact Information"
    assert_select ".is-invalid", count: 0
    assert_select ".has-error", count: 0
    assert_select ".ptfgAlert", count: 0
  end

  test "new has every field, named under order[...]" do
    get order_now_path

    Order::FIELDS.each do |field|
      assert_select "[name='order[#{field}]']", count: 1, message: "expected an order[#{field}] field"
    end
    assert_select "input[name='order[your_email]'][type='email']"
    assert_select "textarea[name='order[additional_comments]']"
  end

  test "the select boxes offer the legacy choices, after a blank one" do
    get order_now_path

    assert_select "select#order_heard_about_us option", count: Order::HEARD_ABOUT_US_CHOICES.size + 1
    assert_select "select#order_heard_about_us option[value='']"
    assert_select "select#order_game_format option", text: "Let It Ride (No Weekend Sub)"
    assert_select "select#order_league_time_zone option", count: Order::TIME_ZONES.size + 1
  end

  test "only the three required fields carry the red asterisk" do
    get order_now_path

    assert_select "label .ptfgRed", count: 3
    assert_select "label[for='order_heard_about_us'] .ptfgRed"
    assert_select "label[for='order_your_name'] .ptfgRed"
    assert_select "label[for='order_your_email'] .ptfgRed"
  end

  test "the intro carries the new-leagues-only note and the minimum-size notice" do
    get order_now_path

    assert_select ".onNew", /This form is for new leagues only/
    assert_select ".onNotice", /#{MIN_TEAMS} or more expected teams/
  end

  test "the hint links open in a new tab, and the game formats one points at the page" do
    get order_now_path

    assert_select "small.onHint a[href='/game_formats'][target='_blank']", "here"
    assert_select "small.onHint a[href*='pgatour.com'][target='_blank'][rel='noopener']"
  end

  test "the reCAPTCHA widget is rendered by the Stimulus controller with this environment's site key" do
    get order_now_path

    assert_select "[data-controller='recaptcha'][data-recaptcha-sitekey-value='#{Rails.configuration.x.recaptcha.site_key}']"
    assert_select "script[src*='recaptcha']", count: 0
  end

  test "the page opts out of Turbo's snapshot cache and guards against a double submit" do
    get order_now_path

    assert_select "meta[name='turbo-cache-control'][content='no-cache']"
    assert_select "button[type='submit'][data-turbo-submits-with]", "Submit"
  end

  test "the sidebar logo is hidden on a phone, where it would push Submit off-screen" do
    get order_now_path

    assert_select ".col-md-4.d-none.d-md-block #ptfglLogo"
  end

  test "Order Now is in the nav, lit up while on it" do
    get order_now_path

    assert_select "nav a.nav-link.active[href='/order_now']", text: "New League Request", count: 1
  end

  test "the nav link stays lit on the thank-you page" do
    submit
    follow_redirect!

    assert_select "nav a.nav-link.active[href='/order_now']", count: 1
  end

  test "legacy's /order_now/new and a GET of /order_now/place_order go to the form" do
    get "/order_now/new"
    assert_redirected_to "/order_now"

    get "/order_now/place_order"
    assert_redirected_to "/order_now"
  end

  # --- placing an order ---

  test "a valid order with a passing reCAPTCHA redirects to thank you" do
    submit

    assert_redirected_to order_now_thank_you_path
    assert_equal "Your request has been submitted.", flash[:notice]
  end

  test "a valid order emails the confirmation to the requester" do
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      submit(your_email: "jane@example.com")
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "jane@example.com" ], mail.to
    assert_equal [ ADMIN_EMAIL ], mail.bcc
  end

  test "an order with only the required fields is accepted" do
    submit(desired_league_name: "", game_format: "", start_tournament: "", end_tournament: "",
           number_of_segments: "", league_time_zone: "", projected_league_size: "", league_password: "",
           additional_comments: "", your_phone: "")

    assert_redirected_to order_now_thank_you_path
  end

  test "the thank-you page confirms the request" do
    submit
    follow_redirect!

    assert_response :success
    assert_select "title", /\AThank You \| /
    assert_select ".ptfgAlert.alert-success", /Your request has been submitted\./
    assert_select ".ctThankYou-text", /A confirmation email with additional details and next steps is on its way/
    assert_select ".ctThankYou a[href='/contact_us']", "contact us"
    assert_select ".ctThankYou a.hmBtn[href='/']", "Back to Home"
  end

  test "a reload of the thank-you page goes home rather than repeating the confirmation" do
    submit
    follow_redirect!
    get order_now_thank_you_path

    assert_redirected_to root_path
  end

  test "the thank-you page, reached directly, goes home" do
    get order_now_thank_you_path

    assert_redirected_to root_path
  end

  test "the reCAPTCHA response from the form is what gets verified" do
    seen = []
    stub_class_method(GoogleRecaptchaVerifier, :verify, with: ->(token) { seen << token; true }) do
      post order_now_path, params: { order: valid_params, "g-recaptcha-response" => "the-widgets-token" }
    end

    assert_equal [ "the-widgets-token" ], seen
  end

  test "values are trimmed before they are emailed" do
    submit(your_name: "  Jane Doe  ")

    assert_includes ActionMailer::Base.deliveries.last.body.to_s, "Dear Jane Doe,"
  end

  # --- what's rejected ---

  test "a missing required field re-renders the form with a message and that field highlighted, without sending" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      submit(your_name: "")
    end

    assert_response :unprocessable_entity
    assert_select ".ptfgAlert.alert-danger", /Please enter all required fields marked in red\./
    assert_select "input#order_your_name.is-invalid"
    assert_select ".form-group.has-error label[for='order_your_name']"
    assert_select ".is-invalid", count: 1
  end

  test "each missing required field is highlighted, each independently" do
    submit(heard_about_us: "", your_name: "", your_email: "")

    assert_select "select#order_heard_about_us.is-invalid"
    assert_select "input#order_your_name.is-invalid"
    assert_select "input#order_your_email.is-invalid"
    assert_select ".is-invalid", count: 3
  end

  test "an invalid email is rejected, naming it, and its field highlighted" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      submit(your_email: "not-an-email")
    end

    assert_response :unprocessable_entity
    assert_select ".ptfgAlert.alert-danger", /'not-an-email' is not a valid e-mail address\./
    assert_select "input#order_your_email.is-invalid"
    assert_select ".is-invalid", count: 1
  end

  test "an address echoed back in the error is escaped, never rendered as markup" do
    submit(your_email: "<script>alert(1)</script>")

    assert_no_match(/<script>alert\(1\)<\/script>/, response.body)
    assert_match(/&lt;script&gt;alert\(1\)&lt;\/script&gt;/, response.body)
  end

  test "a league password with a space is rejected, naming it, without sending" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      submit(league_password: "my secret")
    end

    assert_response :unprocessable_entity
    assert_select ".ptfgAlert.alert-danger", /Your league password 'my secret' cannot contain any space characters\./
  end

  test "values already typed are kept when the form comes back" do
    submit(your_name: "", desired_league_name: "Preserve Me", game_format: "Two & Thru",
           league_time_zone: "Pacific", additional_comments: "Keep this too")

    assert_select "input#order_desired_league_name[value='Preserve Me']"
    assert_select "select#order_game_format option[selected][value='Two & Thru']"
    assert_select "select#order_league_time_zone option[selected]", text: "Pacific"
    assert_select "select#order_heard_about_us option[selected]", text: "Google"
    assert_select "textarea#order_additional_comments", text: /Keep this too/
    assert_select "input#order_your_email[value='john@example.com']"
  end

  test "a missing reCAPTCHA response asks for the Security Challenge, in bold" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      submit(recaptcha_response: nil)
    end

    assert_response :unprocessable_entity
    assert_select ".ptfgAlert.alert-danger b", "Security Challenge"
    assert_select ".ptfgAlert.alert-danger", /I'm not a robot/
  end

  test "a blank reCAPTCHA response is treated as missing" do
    submit(recaptcha_response: "")

    assert_select ".ptfgAlert.alert-danger b", "Security Challenge"
  end

  test "a failing reCAPTCHA shows the unexpected-error message with a Contact Us link, without sending" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      submit(verified: false)
    end

    assert_response :unprocessable_entity
    assert_select ".ptfgAlert.alert-danger", /Unexpected error\./
    assert_select ".ptfgAlert.alert-danger a[href='/contact_us']", "Contact Us"
  end

  test "when Google can't be reached the visitor gets the unexpected-error message, not a server error" do
    GoogleRecaptchaVerifier.poster = ->(_uri, _form) { raise SocketError, "getaddrinfo failed" }
    begin
      capture_log do
        assert_no_difference "ActionMailer::Base.deliveries.size" do
          post order_now_path, params: { order: valid_params, "g-recaptcha-response" => "a-token" }
        end
      end
    ensure
      GoogleRecaptchaVerifier.poster = nil
    end

    assert_response :unprocessable_entity
    assert_select ".ptfgAlert.alert-danger", /Unexpected error\./
  end

  test "the required fields are checked before the reCAPTCHA, so Google isn't asked about an unusable order" do
    asked = false
    stub_class_method(GoogleRecaptchaVerifier, :verify, with: ->(_token) { asked = true }) do
      post order_now_path, params: { order: valid_params(your_name: ""), "g-recaptcha-response" => "a-token" }
    end

    assert_not asked
  end

  test "a post with no order at all gets the required-fields message, not an error page" do
    post order_now_path

    assert_response :unprocessable_entity
    assert_select ".ptfgAlert.alert-danger", /Please enter all required fields marked in red\./
  end

  test "parameters that aren't form fields are ignored" do
    submit(extra_field: "ignored")

    assert_redirected_to order_now_thank_you_path
  end
end
