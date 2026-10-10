require "test_helper"

class LeagueDirectoryTest < ActiveSupport::TestCase
  FIXTURE = Rails.root.join("test/fixtures/files/league_listings.txt").to_s

  def listing(id:, name: id, start: "2026-01-01", format: "One And Done")
    LeagueListing.new(league_id: id, name: name, since: "2018", start_date: Date.parse(start),
                      end_date: Date.parse(start) + 200, league_format: format, entry_fee: "$0",
                      url: "http://#{id.delete(' ')}.test")
  end

  def ids(leagues)
    leagues.map(&:league_id)
  end

  def names(leagues)
    leagues.map(&:name)
  end

  # --- which listings are shown ---

  test "lists every listing" do
    directory = LeagueDirectory.new([ listing(id: "A"), listing(id: "B"), listing(id: "C") ], season: "2026")

    assert_equal %w[A B C], ids(directory.leagues)
  end

  test "the summer pool is listed like any other league, once" do
    directory = LeagueDirectory.new([ listing(id: "Summer"), listing(id: "A") ], season: "2026")

    assert_equal %w[A Summer], ids(directory.leagues)
  end

  test "an empty directory lists nothing" do
    assert_empty LeagueDirectory.new([], season: "2026").leagues
  end

  # --- orderings, on the fixture file's six leagues (season 2026) ---

  test "default orders by name, as plain case-sensitive strings" do
    listed = LeagueDirectory.load(FIXTURE, season: "2026").leagues(:default)

    # Digits, then capitals, then lowercase.
    assert_equal [ "19th Hole Duffers", "AMEN CORNER", "Bottom Feeders", "Summer Golf Pool", "Zulu Gridiron", "amen corner" ],
                 names(listed)
  end

  test "league_name orders by name, like the default" do
    directory = LeagueDirectory.load(FIXTURE, season: "2026")

    assert_equal names(directory.leagues(:default)), names(directory.leagues(:league_name))
  end

  test "league_id orders by id" do
    listed = LeagueDirectory.load(FIXTURE, season: "2026").leagues(:league_id)

    assert_equal %w[ALPHA BETA DELTA EPSILON GAMMA Summer], ids(listed)
  end

  test "league_format groups by format, then orders by name within each" do
    listed = LeagueDirectory.load(FIXTURE, season: "2026").leagues(:league_format)

    assert_equal [ "AMEN CORNER",                                                  # Let It Ride
                   "19th Hole Duffers", "Summer Golf Pool", "Zulu Gridiron",       # One And Done
                   "Bottom Feeders", "amen corner" ],                              # Pick 3 Classic
                 names(listed)
  end

  test "start_date lists this season's leagues first, by date then name, then earlier seasons' the same way" do
    listed = LeagueDirectory.load(FIXTURE, season: "2026").leagues(:start_date)

    assert_equal [ "Zulu Gridiron", "amen corner",    # 2026-01-11 (a tie, so by name)
                   "Summer Golf Pool",                # 2026-04-05
                   "AMEN CORNER",                     # 2026-04-09
                   "19th Hole Duffers",               # 2025-01-04
                   "Bottom Feeders" ],                # 2025-02-01
                 names(listed)
  end

  test "which season counts as current is the one passed in" do
    listed = LeagueDirectory.load(FIXTURE, season: "2025").leagues(:start_date)

    assert_equal [ "19th Hole Duffers", "Bottom Feeders" ], names(listed).first(2)
  end

  test "an unknown order is an error rather than a silently unsorted list" do
    assert_raises(ArgumentError) { LeagueDirectory.new([ listing(id: "A") ], season: "2026").leagues(:bogus) }
  end

  test "ORDERS lists every ordering the page offers" do
    assert_equal %i[default league_name league_id start_date league_format], LeagueDirectory::ORDERS
    LeagueDirectory::ORDERS.each do |order|
      assert_nothing_raised { LeagueDirectory.load(FIXTURE, season: "2026").leagues(order) }
    end
  end

  # --- loading the file ---

  test "load reads the fixture's six leagues" do
    assert_equal 6, LeagueDirectory.load(FIXTURE, season: "2026").leagues.length
  end

  test "load defaults to the path configured for this environment and the current season" do
    travel_to Time.zone.local(2026, 6, 1) do
      assert_equal Rails.configuration.x.league_listings_path, FIXTURE
      assert_equal 6, LeagueDirectory.load.leagues.length
    end
  end

  test "a missing file is an empty directory and a logged warning, not an error" do
    with_captured_log do |log|
      directory = LeagueDirectory.load("/no/such/league_listings.txt", season: "2026")

      assert_empty directory.leagues
      assert_match(%r{League listings file not found: /no/such/league_listings\.txt}, log.string)
    end
  end

  test "blank lines, short lines and bad dates are skipped, and the bad ones logged with their line number" do
    with_tmp_listings(<<~TXT) do |path|
      OK1|First|2018|2018-01-04|2018-06-17|One And Done|$1|http://one.test

      SHORT|Not enough fields
      BADDATE|Bad|2018|2018-02-30|2018-06-17|One And Done|$1|http://bad.test
      OK2|Second|2018|2018-03-01|2018-06-17|One And Done|$1|http://two.test
    TXT
      with_captured_log do |log|
        directory = LeagueDirectory.load(path, season: "2018")

        assert_equal %w[OK1 OK2], ids(directory.leagues(:league_id))
        assert_match(/Skipping unparseable line 3 of #{Regexp.escape(path)}.*SHORT/, log.string)
        assert_match(/Skipping unparseable line 4 of #{Regexp.escape(path)}.*BADDATE/, log.string)
        assert_no_match(/line 2/, log.string, "a blank line is skipped quietly")
      end
    end
  end

  test "a path that can't be read as a file gives an empty directory and a logged error" do
    Dir.mktmpdir do |directory_path|
      with_captured_log do |log|
        directory = LeagueDirectory.load(directory_path, season: "2026")

        assert_empty directory.leagues
        assert_match(/Could not read league listings from #{Regexp.escape(directory_path)}/, log.string)
      end
    end
  end

  private

  def with_tmp_listings(contents)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "league_listings.txt")
      File.write(path, contents)
      yield path
    end
  end

  def with_captured_log
    original = Rails.logger
    log = StringIO.new
    Rails.logger = ActiveSupport::Logger.new(log)
    yield log
  ensure
    Rails.logger = original
  end
end
