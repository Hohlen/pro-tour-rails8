class ContactUsController < ApplicationController
  def new
    @contact_us_form = ContactUsForm.new
  end

  def create
    @contact_us_form = ContactUsForm.new(**contact_us_params.to_h.symbolize_keys)

    # First, and without a word: a bot is the only one who fills in the hidden field, and it shouldn't learn what
    # else it got wrong. (Legacy checked this after validating the visible fields.)
    if @contact_us_form.honeypot_filled?
      Rails.logger.info "Honeypot stopped a Contact Us message (subject: #{@contact_us_form.subject.inspect})"
      redirect_to root_path
      return
    end

    unless @contact_us_form.all_fields_non_blank?
      redisplay "Please enter all fields highlighted in red."
      return
    end

    unless @contact_us_form.from_address_valid?
      redisplay "'#{@contact_us_form.from_email_address}' is not a valid e-mail address."
      return
    end

    if params["g-recaptcha-response"].blank?
      redisplay ("Please click the <b>Security Challenge</b> checkbox:<br>" \
                 "<span style=\"margin-left: 18px; font-weight: bold\">I'm not a robot</span>").html_safe
      return
    end

    unless GoogleRecaptchaVerifier.verify(params["g-recaptcha-response"])
      redisplay ("Unexpected error. If this error continues, please let us know by sending an email to " \
                 "<b>#{ADMIN_EMAIL}</b>. Thank you!").html_safe
      return
    end

    ContactUsMailer.contact_message(@contact_us_form).deliver_now
    flash[:notice] = "Your email has been sent."
    redirect_to contact_us_thank_you_path
  end

  def thank_you
  end

  private

  # fetch (not require): a POST with no contact_us_form at all gets the "enter all fields" message like any other
  # empty submission, rather than a 400 error page. Anything but the form's own fields is dropped, as is a honeypot
  # field when the page doesn't send one.
  def contact_us_params
    params.fetch(:contact_us_form, {}).permit(:from_email_address, :subject, :body, :token)
  end

  # Shows the form again, with what was typed still in it, and a message above. 422 so Turbo renders the response.
  def redisplay(message)
    flash.now[:alert] = message
    render :new, status: :unprocessable_entity
  end
end
