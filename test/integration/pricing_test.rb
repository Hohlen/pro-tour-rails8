require "test_helper"

class PricingTest < ActionDispatch::IntegrationTest
  test "shows the minimum fee and what it covers" do
    get pricing_path

    assert_response :success
    assert_select "title", /\APricing \| Pro Tour Fantasy Golf \d{4}\z/
    assert_select ".prPriceCard-amount", /#{Regexp.escape(MIN_LEAGUE_FEE)}\s*\/ season/
    assert_select ".prPriceCard-sub", "for up to #{MIN_TEAMS} teams"
    assert_select ".prPriceStat", 3
  end

  test "explains billing and lists the payment methods" do
    get pricing_path

    assert_select ".hmFeatureGroup .hmFeatureItem", 4
    assert_select ".prPayMethod img", 3
    assert_select ".prPayMethod img[alt='PayPal']"
    assert_select ".prPayMethod img[alt='Venmo']"
    assert_select ".prPayMethod img[alt='Personal Check']"
  end
end
