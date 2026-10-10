require "test_helper"

class LeagueListingTest < ActiveSupport::TestCase
  LINE = "LEAGUE 7|Amen Corner|2018|2018-01-04|2018-06-17|Pick 3 Classic|$100|http://www.League7.ProTourFantasyGolf.com"

  test "parses a line into its eight fields, with dates as Dates" do
    listing = LeagueListing.parse(LINE)

    assert_equal "LEAGUE 7", listing.league_id
    assert_equal "Amen Corner", listing.name
    assert_equal "2018", listing.since
    assert_equal Date.new(2018, 1, 4), listing.start_date
    assert_equal Date.new(2018, 6, 17), listing.end_date
    assert_equal "Pick 3 Classic", listing.league_format
    assert_equal "$100", listing.entry_fee
    assert_equal "http://www.League7.ProTourFantasyGolf.com", listing.url
  end

  test "formats dates as MM/DD/YY for display" do
    listing = LeagueListing.parse(LINE)

    assert_equal "01/04/18", listing.start_date_formatted
    assert_equal "06/17/18", listing.end_date_formatted
  end

  test "links the schedule and rules pages off the league's own site" do
    listing = LeagueListing.parse(LINE)

    assert_equal "http://www.League7.ProTourFantasyGolf.com/schedule", listing.schedule_url
    assert_equal "http://www.League7.ProTourFantasyGolf.com/rules", listing.rules_url
  end

  test "starts_in? compares the start year, given as a String or an Integer" do
    listing = LeagueListing.parse(LINE)

    assert listing.starts_in?("2018")
    assert listing.starts_in?(2018)
    assert_not listing.starts_in?("2019")
  end

  test "strips whitespace around fields and the line ending" do
    listing = LeagueListing.parse("  ID | Name |2018| 2018-01-04 |2018-06-17| Let It Ride | $5 | http://x.test \r\n")

    assert_equal "ID", listing.league_id
    assert_equal "Name", listing.name
    assert_equal Date.new(2018, 1, 4), listing.start_date
    assert_equal "Let It Ride", listing.league_format
    assert_equal "http://x.test", listing.url
  end

  test "returns nil for lines that aren't a listing" do
    assert_nil LeagueListing.parse("")
    assert_nil LeagueListing.parse("   \n")
    assert_nil LeagueListing.parse(nil)
    assert_nil LeagueListing.parse("ONLY|THREE|FIELDS")
    assert_nil LeagueListing.parse(LINE.sub("|http", "|extra|http")), "too many fields"
    assert_nil LeagueListing.parse(LINE.sub("|http://www.League7.ProTourFantasyGolf.com", "")), "missing the url field"
  end

  test "returns nil for a line in the old nine-field format, with its leading public/private flag" do
    assert_nil LeagueListing.parse("private|#{LINE}")
    assert_nil LeagueListing.parse("public|#{LINE}")
  end

  test "returns nil for a malformed or non-ISO date" do
    assert_nil LeagueListing.parse(LINE.sub("2018-01-04", "2018-13-45"))
    assert_nil LeagueListing.parse(LINE.sub("2018-06-17", "06/17/2018"))
    assert_nil LeagueListing.parse(LINE.sub("2018-01-04", ""))
  end

  test "returns nil rather than raising on bytes that aren't valid UTF-8" do
    assert_nil LeagueListing.parse("ID|Bad \xFF name|2018|2018-01-04|2018-06-17|Let It Ride|$5|http://x.test")
  end
end
