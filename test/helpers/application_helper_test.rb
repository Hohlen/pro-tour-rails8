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

  test "obfuscated_mail_to hex-escapes letters and digits so the address isn't in the page as plain text" do
    link = obfuscated_mail_to("Jo Smith <jo1@example.com>", "email", subject: "A question")

    assert_no_match(/jo1@example\.com/, link)
    assert_no_match(/example/, link)
    # "Jo Smith <jo1@example.com>": letters/digits become %xx; the space, <, @, . and > pass through untouched.
    assert_includes link, 'href="mailto:%4a%6f %53%6d%69%74%68 &lt;%6a%6f%31@%65%78%61%6d%70%6c%65.%63%6f%6d&gt;?subject=A%20question"'
    assert_includes link, ">email</a>"
  end

  test "obfuscated_mail_to passes html options through and omits the subject when none is given" do
    link = obfuscated_mail_to("a@b.co", "Write us", class: "hmBtn")

    assert_includes link, 'class="hmBtn"'
    assert_includes link, 'href="mailto:%61@%62.%63%6f"'
  end

  test "Home is only active on the exact root path, not on every page" do
    request.path = "/"
    assert_equal "nav-link active", nav_link_class("/")

    request.path = "/pricing"
    assert_equal "nav-link", nav_link_class("/")
  end
end
