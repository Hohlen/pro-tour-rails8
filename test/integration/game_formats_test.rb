require "test_helper"

class GameFormatsTest < ActionDispatch::IntegrationTest
  test "shows the four formats, each linked to its rules where it has any" do
    get game_formats_path

    assert_response :success
    assert_select "title", /\AGame Formats \| Pro Tour Fantasy Golf \d{4}\z/
    assert_select "h2#pageTitle", "Game Formats"
    assert_select ".gfCard", 4
    assert_select ".gfCard-title", text: "One & Done Format"
    assert_select ".gfCard-title", text: "Pick 3 Classic Format"
    assert_select ".gfCard-flagship", "Flagship"
    assert_select ".gfCard--blue .gfCard-link[href='#{rules_one_and_done_path}']", "View Full Rules →"
    assert_select ".gfCard--red .gfCard-link[href='#{rules_let_it_ride_path}']"
    assert_select ".gfCard--purple .gfCard-link[href='#{rules_pick_3_classic_path}']"
    # Two & Thru has no rules page of its own: it links to One & Done's from its description instead.
    assert_select ".gfCard--green .gfCard-link", count: 0
    assert_select ".gfCard--green a[href='#{rules_one_and_done_path}']", "One & Done"
  end
end
