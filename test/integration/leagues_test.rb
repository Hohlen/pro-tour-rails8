require "test_helper"

class LeaguesTest < ActionDispatch::IntegrationTest
  # The fixture's start dates are in 2025 and 2026; this pins "this season" to 2026 for the start-date ordering and
  # the table's heading.
  setup { travel_to Time.zone.local(2026, 6, 1) }

  def league_names
    css_select(".lgTable tbody tr td:nth-child(2) a").map(&:text)
  end

  # --- every ordering renders ---

  { "/leagues" => "Default",
    "/leagues/by_league_name" => "League Name",
    "/leagues/by_league_id" => "League ID",
    "/leagues/by_start_date" => "Start Date",
    "/leagues/by_format" => "Format" }.each do |path, label|
    test "#{path} renders with #{label} selected in the dropdown" do
      get path

      assert_response :success
      assert_select "title", /\ALeagues \| Pro Tour Fantasy Golf \d{4}\z/
      assert_select "h2#pageTitle", "Leagues"
      assert_select "select#sort_by option[selected]", count: 1, text: label
      assert_select "select#sort_by option[selected][value='#{path}']"
      assert_select "nav a.nav-link.active[href='/leagues']", count: 1
    end
  end

  test "the dropdown offers all five orderings, each valued by its URL, and is wired to the sort-select controller" do
    get leagues_path

    assert_select "select#sort_by[data-controller='sort-select'][data-action='change->sort-select#go']" do
      assert_select "option", 5
      assert_select "option[value='/leagues/by_league_name']", "League Name"
      assert_select "option[value='/leagues/by_format']", "Format"
    end
  end

  test "/leagues/index, which legacy's dropdown sent for Default, redirects to /leagues" do
    get "/leagues/index"

    assert_redirected_to "/leagues"
  end

  # --- the one table ---

  test "there is a single blue table headed with the current season and the league count" do
    get leagues_path

    assert_select ".lgTableCard", 1
    assert_select ".lgTable", 1
    assert_select ".lgTableCard-head .lgTableCard-title", "2026 Leagues"
    assert_select ".lgTableCard-head .lgTableCard-count", "6 leagues"
  end

  test "the heading follows the season, rolling over to the next year on November 1" do
    travel_to Time.zone.local(2026, 10, 31, 12) do
      get leagues_path
      assert_select ".lgTableCard-title", "2026 Leagues"
    end

    travel_to Time.zone.local(2026, 11, 1, 0, 5) do
      get leagues_path
      assert_select ".lgTableCard-title", "2027 Leagues"
    end
  end

  test "nothing mentions public or private leagues any more" do
    get leagues_path

    assert_select ".lgTableCard-title", text: /Public|Private/, count: 0
    assert_select ".hmHero", text: /public|private/i, count: 0
  end

  test "every league in the file is listed, the summer pool once like the rest" do
    get leagues_path

    assert_equal 6, league_names.length
    assert_equal 1, league_names.count("Summer Golf Pool")
  end

  # --- order ---

  test "default orders by name, case-sensitively" do
    get leagues_path

    assert_equal [ "19th Hole Duffers", "AMEN CORNER", "Bottom Feeders", "Summer Golf Pool", "Zulu Gridiron", "amen corner" ],
                 league_names
  end

  test "by league name matches default" do
    get leagues_by_league_name_path

    assert_equal [ "19th Hole Duffers", "AMEN CORNER", "Bottom Feeders", "Summer Golf Pool", "Zulu Gridiron", "amen corner" ],
                 league_names
  end

  test "by start date puts this season's leagues first" do
    get leagues_by_start_date_path

    assert_equal [ "Zulu Gridiron", "amen corner", "Summer Golf Pool", "AMEN CORNER", "19th Hole Duffers", "Bottom Feeders" ],
                 league_names
  end

  test "by format groups by format then name" do
    get leagues_by_format_path

    assert_equal [ "AMEN CORNER", "19th Hole Duffers", "Summer Golf Pool", "Zulu Gridiron", "Bottom Feeders", "amen corner" ],
                 league_names
  end

  test "by league id shows ids in the name column, in id order, with the name as each link's tooltip" do
    get leagues_by_league_id_path

    assert_select "thead th", text: "League Id", count: 1
    assert_select "thead th", text: "League Name", count: 0
    assert_equal %w[ALPHA BETA DELTA EPSILON GAMMA Summer], league_names
    assert_select "tbody a[href='http://www.Alpha.ProTourFantasyGolf.com'][title='Zulu Gridiron']", "ALPHA"
  end

  test "other orderings label the column League Name and use the id as the tooltip" do
    get leagues_path

    assert_select "thead th", text: "League Name", count: 1
    assert_select "tbody a[href='http://www.Alpha.ProTourFantasyGolf.com'][title='ALPHA']", "Zulu Gridiron"
  end

  # --- the rows ---

  test "rows are numbered from 1" do
    get leagues_path

    assert_equal %w[1 2 3 4 5 6],
                 css_select(".lgTable tbody tr[data-league-filter-target='row'] td:first-child").map(&:text)
  end

  test "each row links the league, its schedule by start date, and its rules by format, opening in new tabs" do
    get leagues_path

    assert_select "tbody a[href='http://www.Alpha.ProTourFantasyGolf.com']", "Zulu Gridiron"
    assert_select "tbody a[href='http://www.Alpha.ProTourFantasyGolf.com/schedule']", "01/11/26"
    assert_select "tbody a[href='http://www.Alpha.ProTourFantasyGolf.com/rules']", "One And Done"
    assert_select "tbody a:not([target='_blank'])", count: 0
    assert_select "tbody a:not([rel='noopener'])", count: 0
  end

  test "tooltips give the league's end date on the date and its first season on the format" do
    get leagues_path

    assert_select "a[href='http://www.Alpha.ProTourFantasyGolf.com/schedule'][title='League Ends 09/20/26']"
    assert_select "a[href='http://www.Alpha.ProTourFantasyGolf.com/rules'][title='Since 2024']"
  end

  # --- stat line ---

  test "the intro uses the wide lead so its one sentence doesn't strand a word on a second line" do
    get leagues_path

    assert_select ".hmHero-lead.hmHero-lead--wide", /Each league is run by its own commissioner/
  end

  test "the stat line gives the league count and the year hosting began" do
    get leagues_path

    assert_select ".lgStats .lgStat", 2
    assert_select ".lgStat:nth-child(1) .lgStat-value", "6"
    assert_select ".lgStat:nth-child(1) .lgStat-label", "Leagues"
    assert_select ".lgStat:nth-child(2) .lgStat-value", SITE_FOUNDED_YEAR.to_s
    assert_select ".lgStat:nth-child(2) .lgStat-label", "Hosting Since"
  end

  test "the stat line's count matches the table's rows and header" do
    get leagues_path

    assert_equal css_select(".lgTable tbody tr[data-league-filter-target=row]").length.to_s,
                 css_select(".lgStat-value").first.text
    assert_select ".lgTableCard-count", "6 leagues"
  end

  # --- live search ---

  test "the search box is in the page but hidden until JavaScript shows it" do
    get leagues_path

    assert_select "[data-controller='league-filter']" do
      assert_select ".lgSearch[hidden][data-league-filter-target='search']" do
        assert_select "input[type='search'][data-league-filter-target='input'][aria-label='Search leagues']"
      end
    end
  end

  test "typing and Escape are wired to the filter and clear actions" do
    get leagues_path

    assert_select "input[data-action~='input->league-filter#filter'][data-action~='keydown.esc->league-filter#clear']"
  end

  test "each row carries its searchable text -- name, id and format, lowercased" do
    get leagues_path

    assert_select "tr[data-league-filter-target='row']", 6
    assert_select "tr[data-search='zulu gridiron alpha one and done']"
    assert_select "tr[data-search='amen corner gamma let it ride']"
  end

  test "the count and a hidden no-match row are there for the filter to update" do
    get leagues_path

    assert_select ".lgTableCard-count[data-league-filter-target='count'][aria-live='polite']", "6 leagues"
    assert_select "tr[hidden][data-league-filter-target='noMatch'] [data-league-filter-target='query']"
  end

  test "zebra stripes go on the odd-numbered rows" do
    get leagues_path

    assert_equal [ true, false, true, false, true, false ],
                 css_select("tr[data-league-filter-target=row]").map { |row| row["class"].to_s.include?("lgRowAlt") }
    assert_select ".lgTable.table-striped", count: 0
  end

  test "the sort dropdown is still there beside the search box" do
    get leagues_path

    assert_select ".lgToolbar .lgSearch"
    assert_select ".lgToolbar .lgSortBar select#sort_by"
  end

  # --- when there's nothing to show ---

  test "with no listings file the table says so, and the page still renders" do
    with_listings_path("/no/such/league_listings.txt") do
      get leagues_path

      assert_response :success
      assert_select ".lgTable-empty", text: "No leagues to display right now.", count: 1
      assert_select ".lgTableCard-count", "0 leagues"
      assert_select ".lgTableCard-title", "2026 Leagues"
      assert_select ".lgStat:nth-child(1) .lgStat-value", "0"
      assert_select ".lgStat:nth-child(1) .lgStat-label", "Leagues"
      assert_select ".lgSearch", count: 0
      assert_select "tr[data-league-filter-target='noMatch']", count: 0
    end
  end

  private

  def with_listings_path(path)
    original = Rails.configuration.x.league_listings_path
    Rails.configuration.x.league_listings_path = path
    yield
  ensure
    Rails.configuration.x.league_listings_path = original
  end
end
