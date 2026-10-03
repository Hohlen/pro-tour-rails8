require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "home page renders with the shared chrome" do
    get root_path

    assert_response :success
    assert_select "title", /Pro Tour Fantasy Golf \d{4} \| Online Hosting For Fantasy Golf Leagues/
    assert_select "h2#pageTitle", "Home Page"
    assert_select "nav.navbar-custom a.navbar-brand", /Pro Tour\s+Fantasy Golf/
    assert_select "#copyright", /KJ Businesses, LLC/
  end

  test "nav links to every top-level page and highlights Home" do
    get root_path

    { "Home" => "/", "Game Formats" => "/game_formats", "Features" => "/features",
      "Screenshots" => "/screenshots", "Pricing" => "/pricing", "Leagues" => "/leagues",
      "FAQs" => "/faqs", "Legal" => "/legal", "Contact Us" => "/contact_us" }.each do |label, path|
      assert_select "nav a.nav-link[href='#{path}']", label
    end
    assert_select "nav a.nav-link.active", count: 1, text: "Home"
  end

  test "Order Now stays out of the nav, as in legacy" do
    get root_path

    assert_select "nav a[href*='order_now']", count: 0
  end

  test "home shows the sales blurb in the sidebar card, not the tagline" do
    get root_path

    assert_select ".card-body", /Dump the spreadsheet/
    assert_select ".ptfgTagline", count: 0
  end

  test "health check responds" do
    get rails_health_check_path

    assert_response :success
  end
end
