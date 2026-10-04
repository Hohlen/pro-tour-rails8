# The Contact Us form's fields and validation rules, as a plain Ruby object. Ported from legacy's
# ContactUsController::EmailMsg (same method names, so its tests port across), pulled into its own file and given
# keyword arguments.
#
# `token` is a honeypot (https://www.gravityforms.com/blog/rip-captcha/): the field is hidden from people, so only
# a bot filling in every field fills it in. It isn't part of all_fields_non_blank? -- requiring it would defeat
# the point.
class ContactUsForm
  attr_reader :from_email_address, :subject, :body, :token

  def initialize(from_email_address: "", subject: "", body: "", token: "")
    @from_email_address = from_email_address.to_s.strip
    # A subject is one line: squish folds any newlines into spaces, so a hand-crafted POST can't put extra headers
    # ("...\r\nBcc: someone@else.com") into the email it becomes the subject of.
    @subject = subject.to_s.squish
    @body = body.to_s.strip
    @token = token.to_s
  end

  def all_fields_non_blank?
    !from_email_address_blank? && !subject_blank? && !body_blank?
  end

  def from_address_valid?
    EMAIL_REG_EXP.match?(from_email_address)
  end

  def from_email_address_blank?
    from_email_address.empty?
  end

  def subject_blank?
    subject.empty?
  end

  def body_blank?
    body.empty?
  end

  def subject_has_error?
    subject_blank?
  end

  def body_has_error?
    body_blank?
  end

  def from_email_address_has_error?
    from_email_address_blank? || !from_address_valid?
  end

  # True when something was typed into the hidden field, which only a bot would do.
  def honeypot_filled?
    token.strip.present?
  end
end
