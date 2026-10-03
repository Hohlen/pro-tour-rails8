require "test_helper"

class FeaturesTest < ActionDispatch::IntegrationTest
  test "describes what commissioners and participants get" do
    get features_path

    assert_response :success
    assert_select "title", /\AFeatures \| Pro Tour Fantasy Golf \d{4}\z/
    assert_select ".hmHero-title", "Be the Commissioner of Your Own Private League"
    assert_select ".hmFeatureGroup--blue .hmFeatureItem", 6
    assert_select ".hmFeatureGroup--green .hmFeatureItem", 3
    assert_select ".gfCard", 3
    assert_select ".hmHero a[href='#{game_formats_path}']", "formats"
  end

  test "the setup fee comes from MIN_LEAGUE_FEE" do
    get features_path

    assert_select ".hmCallout b", MIN_LEAGUE_FEE
  end

  test "both contact links are mailto links that keep the address out of the page as plain text" do
    get features_path

    assert_select ".hmCallout a[href^='mailto:%']", 2
    assert_select ".hmCallout a.hmBtn", "Contact Us About A League"
    assert_no_match(/FantasyGolfCommissioner/i, response.body)
    assert_select ".hmCallout a[href*='subject=PTFG%20Private%20League%20Inquiry']", 2
  end
end
