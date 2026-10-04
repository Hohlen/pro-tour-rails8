require "test_helper"

# The one still-unported page (Phase 3: Contact Us). Delete this file along with PlaceholdersController once it's
# ported.
class PlaceholdersTest < ActionDispatch::IntegrationTest
  test "/contact_us renders a placeholder and lights its own nav link" do
    get "/contact_us"

    assert_response :success
    assert_select "title", /\AContact Us \| Pro Tour Fantasy Golf \d{4}\z/
    assert_select "h2#pageTitle", "Contact Us"
    assert_select ".hmHero-eyebrow", "Coming Soon"
    assert_select "nav a.nav-link.active[href='/contact_us']", count: 1
  end
end
