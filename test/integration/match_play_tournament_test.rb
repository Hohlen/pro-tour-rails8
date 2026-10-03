require "test_helper"

class MatchPlayTournamentTest < ActionDispatch::IntegrationTest
  test "renders the overview with the season in the heading" do
    travel_to Time.zone.local(2026, 3, 1) do
      get match_play_tournament_path

      assert_response :success
      assert_select "title", /\AMatch Play Tournament Details \| Pro Tour Fantasy Golf 2026\z/
      assert_select "h2#pageTitle", "2026 Match Play Championship Details"
      assert_select ".card-header.ptfgBluePanelBackground .card-title", "Overview"
      assert_select ".card-body", /total purse for 2026 is \$20 million/
    end
  end

  test "payout table has a header row and ten places, top to bottom" do
    get match_play_tournament_path

    assert_select "table.table-striped thead tr.ptfgWhiteOnGreen td", 2
    assert_select "table tbody tr", 10
    assert_select "table tbody tr:first-child td:nth-child(1)", "1st"
    assert_select "table tbody tr:first-child td:nth-child(2)", "$3,500,000"
    assert_select "table tbody tr:last-child td:nth-child(1)", "51-64"
    assert_select "table tbody tr:last-child td:nth-child(2)", "~$70,000"
  end

  test "strategy tips link to the two rules pages it mentions, in new tabs" do
    get match_play_tournament_path

    assert_select "a[href='#{rules_one_and_done_path}'][target='_blank']", "One & Done"
    assert_select "a[href='#{rules_pick_3_classic_path}'][target='_blank']", "Pick 3 Classic"
  end
end
