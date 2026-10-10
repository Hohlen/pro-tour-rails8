# One line of league_listings.txt, which is pipe-delimited:
#
#   LEAGUE ID|League Name|2018|2018-01-04|2018-06-17|Pick 3 Classic|$25|http://www.League1.ProTourFantasyGolf.com
#   id        name        since start      end        format         fee  league site url
#
# Ported from legacy's LeaguesController::LeagueListing, minus its leading public/private flag: every league is
# private now, and the file no longer says so. `format` is `league_format` here so it doesn't shadow
# Kernel#format, dates are parsed into Dates instead of being kept as YYYY-MM-DD strings (which sorted correctly,
# but only because ISO dates happen to), and a line that doesn't parse returns nil instead of raising.
class LeagueListing
  FIELD_COUNT = 8

  attr_reader :league_id, :name, :since, :start_date, :end_date, :league_format, :entry_fee, :url

  # Returns the listing for +line+, or nil if it's blank, has the wrong number of fields, or has a bad date.
  def self.parse(line)
    fields = line.to_s.split("|", -1).map(&:strip)
    return nil unless fields.length == FIELD_COUNT

    league_id, name, since, start_date, end_date, league_format, entry_fee, url = fields
    new(league_id: league_id, name: name, since: since,
        start_date: Date.strptime(start_date, "%Y-%m-%d"), end_date: Date.strptime(end_date, "%Y-%m-%d"),
        league_format: league_format, entry_fee: entry_fee, url: url)
  rescue ArgumentError
    nil # Date.strptime raises ArgumentError on a malformed date
  end

  def initialize(league_id:, name:, since:, start_date:, end_date:, league_format:, entry_fee:, url:)
    @league_id = league_id
    @name = name
    @since = since
    @start_date = start_date
    @end_date = end_date
    @league_format = league_format
    @entry_fee = entry_fee
    @url = url
  end

  # "02/25/12", the way the Leagues page shows dates.
  def start_date_formatted
    start_date.strftime("%m/%d/%y")
  end

  def end_date_formatted
    end_date.strftime("%m/%d/%y")
  end

  # The league site's schedule and rules pages, which the Start Date and Format columns link to.
  def schedule_url
    "#{url}/schedule"
  end

  def rules_url
    "#{url}/rules"
  end

  def starts_in?(year)
    start_date.year.to_s == year.to_s
  end
end
