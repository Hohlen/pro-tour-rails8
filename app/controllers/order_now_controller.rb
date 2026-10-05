class OrderNowController < ApplicationController
  def new
    @order = Order.new
  end

  def create
    @order = Order.new(**order_params.to_h.symbolize_keys)

    if !@order.all_required_fields_entered?
      redisplay "Please enter all required fields marked in red."
    elsif !@order.email_address_valid?
      redisplay "'#{@order.your_email}' is not a valid e-mail address."
    elsif @order.league_password_contains_password?
      redisplay "Your league password '#{@order.league_password}' cannot contain any space characters."
    elsif params["g-recaptcha-response"].blank?
      redisplay ("Please click the <b>Security Challenge</b> checkbox:<br>" \
                 "<span style=\"margin-left: 18px; font-weight: bold\">I'm not a robot</span>").html_safe
    elsif !GoogleRecaptchaVerifier.verify(params["g-recaptcha-response"])
      redisplay "Unexpected error. If this error continues, please let us know via the " \
                "#{helpers.link_to("Contact Us", contact_us_path)} page.".html_safe
    else
      OrderMailer.order_confirmation(@order).deliver_now
      flash[:notice] = "Your request has been submitted."
      flash[:order_placed] = true # for the Thank You page
      redirect_to order_now_thank_you_path
    end
  end

  def thank_you
    # Nothing in the flash means a refresh (F5) after landing here, or someone typing the URL directly.
    redirect_to root_path unless flash[:order_placed]
  end

  private

  # fetch (not require): a POST with no order at all gets the "enter all required fields" message like any other
  # empty submission, rather than a 400 error page. Anything but the form's own fields is dropped.
  def order_params
    params.fetch(:order, {}).permit(*Order::FIELDS)
  end

  # Shows the form again, with what was typed still in it, and a message above. 422 so Turbo renders the response.
  def redisplay(message)
    flash.now[:alert] = message
    render :new, status: :unprocessable_entity
  end
end
