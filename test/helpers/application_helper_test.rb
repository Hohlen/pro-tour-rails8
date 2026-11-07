require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "page_title_tag falls back to the home page title when a page sets none" do
    travel_to Time.zone.local(2026, 3, 1) do
      assert_equal "Pro Tour Fantasy Golf 2026 | Online Hosting For Fantasy Golf Leagues", page_title_tag
    end
  end

  test "page_title_tag puts the page name first, then the site and season" do
    travel_to Time.zone.local(2026, 3, 1) do
      content_for :title, "Pricing"
      assert_equal "Pricing | Pro Tour Fantasy Golf 2026", page_title_tag
    end
  end

  test "nav_link_class marks the exact path active" do
    request.path = "/pricing"
    assert_equal "nav-link active", nav_link_class("/pricing")
    assert_equal "nav-link", nav_link_class("/faqs")
  end

  test "nav_link_class keeps a section active on its sub-pages, like legacy's module_item" do
    request.path = "/leagues/by_league_name"
    assert_equal "nav-link active", nav_link_class("/leagues")

    request.path = "/contact_us/thank_you"
    assert_equal "nav-link active", nav_link_class("/contact_us")
  end

  test "nav_link_class does not match a path that merely shares a prefix" do
    request.path = "/legalese"
    assert_equal "nav-link", nav_link_class("/legal")
  end

  test "Home is only active on the exact root path, not on every page" do
    request.path = "/"
    assert_equal "nav-link active", nav_link_class("/")

    request.path = "/pricing"
    assert_equal "nav-link", nav_link_class("/")
  end
end
