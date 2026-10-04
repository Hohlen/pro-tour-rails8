require "test_helper"

# Ported from legacy's test/functional/contact_us_controller_test.rb, plus the hardening the port added.
class ContactUsTest < ActionDispatch::IntegrationTest
  def valid_params(overrides = {})
    { from_email_address: "jane@example.com", subject: "Question about leagues",
      body: "How many golfers can I pick each week?", token: "" }.merge(overrides)
  end

  # Sends the form with Google's verdict stubbed, so these never reach Google. Any other keyword overrides a form
  # field (submit(subject: "")); verified: is Google's answer, recaptcha_response: what the widget put in the form
  # (nil for none), and extra: any additional top-level parameters.
  def submit(verified: true, recaptcha_response: "stubbed-token", extra: {}, **field_overrides)
    params = { contact_us_form: valid_params(field_overrides) }
    params["g-recaptcha-response"] = recaptcha_response if recaptcha_response
    stub_class_method(GoogleRecaptchaVerifier, :verify, verified) { post contact_us_path, params: params.merge(extra) }
  end

  # --- the blank form ---

  test "new renders the form with its three labeled fields and no error state" do
    get contact_us_path

    assert_response :success
    assert_select "title", /\AContact Us \| Pro Tour Fantasy Golf \d{4}\z/
    assert_select "h2#pageTitle", "Contact Us"
    assert_select "form.ctForm[action='/contact_us'][method='post']"
    assert_select "label.control-label[for='contact_us_form_from_email_address']", "Your Email Address"
    assert_select "label.control-label[for='contact_us_form_subject']", "Subject"
    assert_select "label.control-label[for='contact_us_form_body']", "Body"
    assert_select "input#contact_us_form_from_email_address[type='email']"
    assert_select ".is-invalid", count: 0
    assert_select ".has-error", count: 0
    assert_select ".alert", count: 0
    assert_select "nav a.nav-link.active[href='/contact_us']", count: 1
  end

  test "the form has the honeypot, hidden from people and assistive tech and out of the tab order" do
    get contact_us_path

    assert_select "input.ctHoneypot#contact_us_form_token[tabindex='-1'][autocomplete='off'][aria-hidden='true']"
  end

  test "the reCAPTCHA widget is rendered by the Stimulus controller with this environment's site key" do
    get contact_us_path

    assert_select "[data-controller='recaptcha'][data-recaptcha-sitekey-value='#{Rails.configuration.x.recaptcha.site_key}']"
    assert_select "script[src*='recaptcha']", count: 0, message: "the controller loads Google's script, not the page"
  end

  test "the page opts out of Turbo's snapshot cache, so a rendered widget is never replayed into itself" do
    get contact_us_path

    assert_select "meta[name='turbo-cache-control'][content='no-cache']"
  end

  test "the submit button guards against a double submit" do
    get contact_us_path

    assert_select "button[type='submit'][data-turbo-submits-with]", "Submit"
  end

  test "the sidebar logo is hidden on a phone, where it would push Submit off-screen" do
    get contact_us_path

    assert_select ".col-md-4.d-none.d-md-block #ptfglLogo"
  end

  test "the intro matches legacy's wording" do
    get contact_us_path

    assert_select ".hmHero-eyebrow", "Email"
    assert_select ".hmHero-lead", "We can be reached via e-mail using the form below:"
  end

  # --- sending ---

  test "a valid message with a passing reCAPTCHA redirects to thank you and emails the commissioner" do
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      submit
    end

    assert_redirected_to contact_us_thank_you_path
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ ADMIN_EMAIL ], mail.to
    assert_equal [ "jane@example.com" ], mail.reply_to
    assert_equal "Question about leagues", mail.subject
    assert_equal "How many golfers can I pick each week?", mail.body.to_s.strip
  end

  test "the thank-you page confirms the send" do
    submit
    follow_redirect!

    assert_response :success
    assert_select "title", /\AThank You \| /
    assert_select ".ptfgAlert.alert-success", /Your email has been sent\./
    assert_select ".ctThankYou-text", /We will respond to you shortly\./
    assert_select ".ctThankYou a.hmBtn[href='/']", "Back to Home"
    assert_select "nav a.nav-link.active[href='/contact_us']", count: 1
  end

  test "the confirmation shows once, not again on a reload" do
    submit
    follow_redirect!
    get contact_us_thank_you_path

    assert_select ".ptfgAlert", count: 0
  end

  test "the reCAPTCHA response from the form is what gets verified" do
    seen = []
    stub_class_method(GoogleRecaptchaVerifier, :verify, with: ->(token) { seen << token; true }) do
      post contact_us_path, params: { contact_us_form: valid_params, "g-recaptcha-response" => "the-widgets-token" }
    end

    assert_equal [ "the-widgets-token" ], seen
  end

  test "a message is sent as the visitor typed it, trimmed" do
    submit(subject: "  Spaced out  ", body: "  Line one\n\nLine two  ")

    mail = ActionMailer::Base.deliveries.last
    assert_equal "Spaced out", mail.subject
    assert_equal "Line one\n\nLine two", mail.body.to_s.strip
  end

  # --- what's rejected ---

  test "blank fields re-render the form with a message and field highlighting, without sending" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      submit(subject: "")
    end

    assert_response :unprocessable_entity
    assert_select ".ptfgAlert.alert-danger", /Please enter all fields highlighted in red\./
    assert_select "input#contact_us_form_subject.is-invalid"
    assert_select ".form-group.has-error label[for='contact_us_form_subject']"
    assert_select ".is-invalid", count: 1
    assert_select "nav a.nav-link.active[href='/contact_us']", count: 1
  end

  test "every blank field is highlighted, each independently" do
    submit(from_email_address: "", subject: "", body: "")

    assert_select ".is-invalid", count: 3
    assert_select ".form-group.has-error", count: 3
  end

  test "values already typed are kept when the form comes back" do
    submit(subject: "", body: "Preserve me", from_email_address: "keep@example.com")

    assert_select "textarea#contact_us_form_body", text: /Preserve me/
    assert_select "input#contact_us_form_from_email_address[value='keep@example.com']"
  end

  test "an invalid from address is rejected, naming it, and its field highlighted" do
    submit(from_email_address: "not-an-email")

    assert_response :unprocessable_entity
    assert_select ".ptfgAlert.alert-danger", /'not-an-email' is not a valid e-mail address\./
    assert_select "input#contact_us_form_from_email_address.is-invalid"
  end

  test "an address echoed back in the error is escaped, never rendered as markup" do
    submit(from_email_address: "<script>alert(1)</script>")

    assert_response :unprocessable_entity
    assert_no_match(/<script>alert\(1\)<\/script>/, response.body)
    assert_match(/&lt;script&gt;alert\(1\)&lt;\/script&gt;/, response.body)
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

  test "a failing reCAPTCHA shows the unexpected-error message with the commissioner's address, without sending" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      submit(verified: false)
    end

    assert_response :unprocessable_entity
    assert_select ".ptfgAlert.alert-danger", /Unexpected error\./
    assert_select ".ptfgAlert.alert-danger b", ADMIN_EMAIL
    assert_select ".ptfgAlert.alert-danger", { text: /via by/, count: 0 }, "legacy's typo is fixed"
  end

  test "when Google can't be reached the visitor gets the unexpected-error message, not a server error" do
    GoogleRecaptchaVerifier.poster = ->(_uri, _form) { raise SocketError, "getaddrinfo failed" }
    begin
      capture_log do
        assert_no_difference "ActionMailer::Base.deliveries.size" do
          post contact_us_path, params: { contact_us_form: valid_params, "g-recaptcha-response" => "a-token" }
        end
      end
    ensure
      GoogleRecaptchaVerifier.poster = nil
    end

    assert_response :unprocessable_entity
    assert_select ".ptfgAlert.alert-danger", /Unexpected error\./
  end

  # --- the honeypot ---

  test "a filled-in honeypot is silently sent home, with nothing emailed" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      submit(token: "i-am-a-bot")
    end

    assert_redirected_to root_path
  end

  test "the honeypot is checked before anything else, so a bot's other mistakes tell it nothing" do
    submit(token: "i-am-a-bot", subject: "", from_email_address: "nonsense", recaptcha_response: nil)

    assert_redirected_to root_path
  end

  test "the honeypot stop is logged" do
    log = capture_log { submit(token: "i-am-a-bot", subject: "Buy cheap pills") }

    assert_match(/Honeypot stopped a Contact Us message \(subject: "Buy cheap pills"\)/, log)
  end

  # --- hostile or malformed submissions ---

  test "a subject with a line break can't add headers to the email" do
    submit(subject: "Hello\r\nBcc: someone@else.com")

    mail = ActionMailer::Base.deliveries.last
    assert_equal "Hello Bcc: someone@else.com", mail.subject
    assert_nil mail.bcc
  end

  test "a POST with no form fields at all gets the usual message, not an error page" do
    post contact_us_path

    assert_response :unprocessable_entity
    assert_select ".ptfgAlert.alert-danger", /Please enter all fields highlighted in red\./
  end

  test "fields the form doesn't have are ignored, inside the form's params or out" do
    stub_class_method(GoogleRecaptchaVerifier, :verify, true) do
      post contact_us_path, params: { contact_us_form: valid_params.merge(to: "attacker@example.com",
                                                                          bcc: "attacker@example.com"),
                                      to: "attacker@example.com", "g-recaptcha-response" => "a-token" }
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ ADMIN_EMAIL ], mail.to
    assert_nil mail.bcc
  end

  test "array or hash values in a field don't break the form" do
    post contact_us_path, params: { contact_us_form: { subject: [ "a", "b" ], body: { x: "y" },
                                                       from_email_address: "jane@example.com" } }

    assert_response :unprocessable_entity
    assert_select ".ptfgAlert.alert-danger", /Please enter all fields highlighted in red\./
  end

  test "legacy's GET to /contact_us/send_email redirects to the form" do
    get "/contact_us/send_email"

    assert_redirected_to "/contact_us"
  end
end
