require "test_helper"

class CommissionersCornerTest < ActionDispatch::IntegrationTest
  test "renders the intro alert and three colored panels" do
    get commissioners_corner_path

    assert_response :success
    assert_select "title", /\ACommissioner's Corner \| Pro Tour Fantasy Golf \d{4}\z/
    assert_select ".alert.alert-danger"
    assert_select ".card-header.ptfgBluePanelBackground .card-title", /League Schedules/
    assert_select ".card-header.ptfgGreenPanelBackground .card-title", /What's New For/
    assert_select ".card-header.ptfgRedPanelBackground .card-title", "Reminders & Other Tips"
  end

  test "is a full-width page: no sidebar logo card" do
    get commissioners_corner_path

    assert_select "#ptfglLogo", count: 0
  end

  test "the season in the headings and copy follows CurrentSeason, rolling over on November 1" do
    travel_to Time.zone.local(2026, 6, 1) do
      get commissioners_corner_path
      assert_select "h2#pageTitle", "Commissioner's Corner 2026"
      assert_select ".card-title", /2026 League Schedules/
      assert_select ".card-body", /same setup as 2025/
    end

    travel_to Time.zone.local(2026, 11, 1, 0, 5) do
      get commissioners_corner_path
      assert_select "h2#pageTitle", "Commissioner's Corner 2027"
      assert_select ".card-body", /same setup as 2026/
    end
  end

  test "the minimum fee comes from MIN_LEAGUE_FEE" do
    get commissioners_corner_path

    assert_select ".card-body b", MIN_LEAGUE_FEE
  end

  test "the spam warning is bolded as a whole (legacy's had a stray empty <b></b> before it)" do
    get commissioners_corner_path

    assert_select ".card-body li b", text: "don’t mark PTFG emails as spam"
  end
end
