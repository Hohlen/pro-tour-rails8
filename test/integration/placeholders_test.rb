require "test_helper"

# Phase 0 only: delete along with PlaceholdersController as each page is ported to its real controller.
class PlaceholdersTest < ActionDispatch::IntegrationTest
  {
    "/game_formats" => "Game Formats",
    "/features" => "Features",
    "/screenshots" => "Screenshots",
    "/pricing" => "Pricing",
    "/leagues" => "Leagues",
    "/faqs" => "FAQs",
    "/legal" => "Legal Terms & Conditions",
    "/contact_us" => "Contact Us"
  }.each do |path, title|
    test "#{path} renders a placeholder titled #{title} and lights its own nav link" do
      get path

      assert_response :success
      assert_select "title", /\A#{Regexp.escape(ERB::Util.html_escape(title))} \| Pro Tour Fantasy Golf \d{4}\z/
      assert_select "h2#pageTitle", title
      assert_select "nav a.nav-link.active[href='#{path}']", count: 1
      assert_select ".ptfgTagline", "Where a bad round never spoils the fun!"
    end
  end
end
