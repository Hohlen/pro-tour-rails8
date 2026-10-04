require "test_helper"

class LeaguesHelperTest < ActionView::TestCase
  test "league_sort_path maps each ordering to its URL" do
    assert_equal "/leagues", league_sort_path(:default)
    assert_equal "/leagues/by_league_name", league_sort_path(:league_name)
    assert_equal "/leagues/by_league_id", league_sort_path(:league_id)
    assert_equal "/leagues/by_start_date", league_sort_path(:start_date)
    assert_equal "/leagues/by_format", league_sort_path(:league_format)
  end

  test "every ordering the directory supports has a URL and a dropdown entry" do
    assert_equal LeagueDirectory::ORDERS, LeaguesHelper::SORT_CHOICES.map(&:last)
    assert(LeagueDirectory::ORDERS.all? { |order| league_sort_path(order).present? })
  end

  test "the dropdown lists the choices in legacy's order, each valued by its URL" do
    assert_equal [ [ "Default", "/leagues" ],
                   [ "League Name", "/leagues/by_league_name" ],
                   [ "League ID", "/leagues/by_league_id" ],
                   [ "Start Date", "/leagues/by_start_date" ],
                   [ "Format", "/leagues/by_format" ] ],
                 league_sort_options
  end

  test "only the League ID ordering shows ids in the name column" do
    @order = :league_id
    assert league_sort_by_id?

    %i[default league_name start_date league_format].each do |order|
      @order = order
      assert_not league_sort_by_id?, "#{order} shouldn't show ids"
    end
  end
end
