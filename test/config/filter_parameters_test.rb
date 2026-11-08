require "test_helper"

# What the request log shows of a submitted form (Rails logs each request's parameters after this filter).
class FilterParametersTest < ActiveSupport::TestCase
  def filtered(params)
    ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(params)
  end

  test "the email addresses typed into Contact Us and Order Now are left in the log" do
    assert_equal "jane@example.com",
                 filtered("contact_us_form" => { "from_email_address" => "jane@example.com" })["contact_us_form"]["from_email_address"]
    assert_equal "jane@example.com", filtered("order" => { "your_email" => "jane@example.com" })["order"]["your_email"]
  end

  test "league passwords are still filtered" do
    assert_equal "[FILTERED]", filtered("order" => { "league_password" => "hunter2" })["order"]["league_password"]
  end
end
