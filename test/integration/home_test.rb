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
      "New League Request" => "/order_now", "FAQs" => "/faqs", "Legal" => "/legal", "Contact Us" => "/contact_us" }.each do |label, path|
      assert_select "nav a.nav-link[href='#{path}']", label
    end
    assert_select "nav a.nav-link.active", count: 1, text: "Home"
  end

  test "home shows the sales blurb in the sidebar card, not the tagline" do
    get root_path

    assert_select ".card-body", /Dump the spreadsheet/
    assert_select ".ptfgTagline", count: 0
  end

  test "the hero's eyebrow says how long PTFG has been hosting leagues" do
    get root_path

    assert_select ".hmHero-eyebrow", "Since #{SITE_FOUNDED_YEAR}"
  end

  test "hero links to Game Formats and Screenshots" do
    get root_path

    assert_select ".hmHero-ctaRow a.hmBtn--primary[href='#{game_formats_path}']", "Explore Game Formats"
    assert_select ".hmHero-ctaRow a.hmBtn--outline[href='#{screenshots_path}']", "View Screenshots"
  end

  test "carousel has ten slides, the first active, and working prev/next controls" do
    get root_path

    assert_select "#homeCarousel[data-bs-ride='carousel']" do
      assert_select ".carousel-item", 10
      assert_select ".carousel-item.active", 1
      assert_select ".carousel-item:first-child.active img[alt='Standings']"
      assert_select ".carousel-item img[alt='Dump The Spreadsheet']"
      assert_select "button.carousel-control-prev[data-bs-target='#homeCarousel'][data-bs-slide='prev']"
      assert_select "button.carousel-control-next[data-bs-target='#homeCarousel'][data-bs-slide='next']"
    end
  end

  test "lists both feature groups, the first linking to Game Formats" do
    get root_path

    assert_select ".hmFeatureGroup--blue .hmFeatureItem", 4
    assert_select ".hmFeatureGroup--green .hmFeatureItem", 7
    assert_select ".hmFeatureGroup--blue a[href='#{game_formats_path}']", "game formats"
  end

  test "health check responds" do
    get rails_health_check_path

    assert_response :success
  end
end
