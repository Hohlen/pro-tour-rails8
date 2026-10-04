require "test_helper"

# Ported from legacy's test/unit/email_msg_test.rb (EmailMsg is now ContactUsForm), plus what the port added: the
# honeypot field, and normalizing what's typed before it's validated.
class ContactUsFormTest < ActiveSupport::TestCase
  def form(overrides = {})
    ContactUsForm.new(**{ from_email_address: "jane@example.com", subject: "Question about leagues",
                          body: "How many golfers can I pick each week?", token: "" }.merge(overrides))
  end

  # --- all_fields_non_blank? ---

  test "all_fields_non_blank? is true when fully filled in" do
    assert form.all_fields_non_blank?
  end

  test "all_fields_non_blank? is true even when the honeypot token is blank (it's meant to be)" do
    assert form(token: "").all_fields_non_blank?
  end

  test "all_fields_non_blank? is false when from_email_address is blank" do
    assert_not form(from_email_address: "").all_fields_non_blank?
  end

  test "all_fields_non_blank? is false when subject is blank" do
    assert_not form(subject: "").all_fields_non_blank?
  end

  test "all_fields_non_blank? is false when body is blank" do
    assert_not form(body: "").all_fields_non_blank?
  end

  test "all_fields_non_blank? is false when a field is only whitespace" do
    assert_not form(subject: "   ").all_fields_non_blank?
    assert_not form(body: "\n\t \n").all_fields_non_blank?
  end

  # --- from_address_valid? ---

  test "from_address_valid? is true for a well-formed address" do
    assert form(from_email_address: "jane@example.com").from_address_valid?
    assert form(from_email_address: "jane.doe+golf@mail.example.co.uk").from_address_valid?
  end

  test "from_address_valid? is false without an at sign" do
    assert_not form(from_email_address: "not-an-email").from_address_valid?
  end

  test "from_address_valid? is false without a domain suffix" do
    assert_not form(from_email_address: "jane@example").from_address_valid?
  end

  test "from_address_valid? rejects a second line smuggled in after a valid address (legacy's ^...$ regexp let it through)" do
    assert_not form(from_email_address: "jane@example.com\nBcc: someone@else.com").from_address_valid?
  end

  # --- the *_has_error? methods the view uses ---

  test "subject_has_error? is true when blank and false when present" do
    assert form(subject: "").subject_has_error?
    assert_not form(subject: "Hello").subject_has_error?
  end

  test "body_has_error? is true when blank and false when present" do
    assert form(body: "").body_has_error?
    assert_not form(body: "Hello there").body_has_error?
  end

  test "from_email_address_has_error? is true when blank" do
    assert form(from_email_address: "").from_email_address_has_error?
  end

  test "from_email_address_has_error? is true when present but invalid" do
    assert form(from_email_address: "not-an-email").from_email_address_has_error?
  end

  test "from_email_address_has_error? is false when valid" do
    assert_not form(from_email_address: "jane@example.com").from_email_address_has_error?
  end

  # --- normalizing what's typed ---

  test "a blank form has empty fields" do
    blank = ContactUsForm.new

    assert_equal "", blank.from_email_address
    assert_equal "", blank.subject
    assert_equal "", blank.body
    assert_not blank.all_fields_non_blank?
    assert_not blank.honeypot_filled?
  end

  test "leading and trailing whitespace is stripped from every field" do
    cleaned = form(from_email_address: "  jane@example.com \n", subject: "  Hi  ", body: "\n  Hello there \n")

    assert_equal "jane@example.com", cleaned.from_email_address
    assert_equal "Hi", cleaned.subject
    assert_equal "Hello there", cleaned.body
  end

  test "a subject is folded to one line, so it can't carry extra email headers" do
    injected = form(subject: "Hello\r\nBcc: someone@else.com")

    assert_equal "Hello Bcc: someone@else.com", injected.subject
    assert_no_match(/[\r\n]/, injected.subject)
  end

  test "a body keeps its own line breaks and spacing" do
    assert_equal "Line one\n\nLine   three", form(body: "Line one\n\nLine   three").body
  end

  test "nil fields are treated as empty rather than raising" do
    nils = ContactUsForm.new(from_email_address: nil, subject: nil, body: nil, token: nil)

    assert_not nils.all_fields_non_blank?
    assert_not nils.honeypot_filled?
  end

  # --- honeypot ---

  test "honeypot_filled? is true only when something was typed into the token field" do
    assert form(token: "i-am-a-bot").honeypot_filled?
    assert_not form(token: "").honeypot_filled?
    assert_not form(token: "   ").honeypot_filled?
  end
end
