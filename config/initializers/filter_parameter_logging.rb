# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
#
# :email is deliberately not in the list (Rails' default has it): the Contact Us and Order Now forms' email addresses
# (contact_us_form[from_email_address], order[your_email]) should show in the request log, to follow up on a
# message or an order that didn't go through. League passwords are still filtered (:passw).
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc
]
