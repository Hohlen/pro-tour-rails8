require "test_helper"

class RulesTest < ActionDispatch::IntegrationTest
  {
    rules_one_and_done_path: [ "One And Done Rules", ".ptfgBluePanelBackground" ],
    rules_let_it_ride_path: [ "Let It Ride Rules", ".ptfgRedPanelBackground" ],
    rules_pick_3_classic_path: [ "Pick 3 Classic Rules", ".ptfgBluePanelBackground" ]
  }.each do |path_helper, (title, header_class)|
    test "#{title} renders its basic and detailed rule panels" do
      get send(path_helper)

      assert_response :success
      assert_select "title", /\A#{Regexp.escape(title)} \| Pro Tour Fantasy Golf \d{4}\z/
      assert_select "h2#pageTitle", title
      assert_select ".card-header#{header_class} .card-title", 2
      assert_select ".card-header .card-title", text: "Basic Rules"
      assert_select ".card-header .card-title", text: "Detailed Rules"
    end

    test "#{title}'s 'More...' anchors each point at a heading in the detailed rules" do
      get send(path_helper)

      %w[Objective ScoringSystem NoShowRules SeasonDuration Prizes].each do |anchor|
        assert_select "a[href='##{anchor}']", minimum: 1
        assert_select "##{anchor}", 1
      end
    end

    test "#{title} includes the shared alternate-pick rules with their three checked, disabled boxes" do
      get send(path_helper)

      assert_select "#NoShowRules", "Alternate Pick / No Shows"
      %w[DNS DQ WD].each do |box|
        assert_select "input[type=checkbox]##{box}[checked][disabled]", 1
      end
    end
  end

  test "Let It Ride and Pick 3 Classic carry the 2-10 usages note; One and Done says ONCE" do
    get rules_let_it_ride_path
    assert_select ".card-body", /2-10 times\*/

    get rules_pick_3_classic_path
    assert_select ".card-body", /2-10 times\*/

    get rules_one_and_done_path
    assert_select ".card-body", /only use a golfer ONCE/
  end
end
