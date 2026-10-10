# The leagues shown on the Leagues page, loaded from league_listings.txt and sorted one of five ways.
# Ported from legacy's LeaguesController (its common_setup and per-action sorts), pulled out of the controller so
# the rules are testable without a request.
#
# Legacy showed two tables, Public and Private, from a flag on each line of the file. Every league is private now,
# the flag is gone, and the page lists every line in the file as one set of leagues.
class LeagueDirectory
  ORDERS = %i[default league_name league_id start_date league_format].freeze

  # Reads +path+ and returns the directory for it. A missing or unreadable file gives an empty directory (and a
  # log line) rather than an error page: legacy treated a missing file as "no leagues", and an I/O error there
  # called `exit`, taking the whole server down.
  def self.load(path = Rails.configuration.x.league_listings_path, season: CurrentSeason.year)
    new(read_listings(path), season: season)
  end

  def self.read_listings(path)
    unless File.exist?(path)
      Rails.logger.warn("League listings file not found: #{path}")
      return []
    end

    File.readlines(path, chomp: true).filter_map.with_index(1) do |line, number|
      next if line.strip.empty?

      LeagueListing.parse(line) || begin
        Rails.logger.warn("Skipping unparseable line #{number} of #{path}: #{line.inspect}")
        nil
      end
    end
  rescue SystemCallError, IOError, EncodingError => e
    Rails.logger.error("Could not read league listings from #{path}: #{e.class}: #{e.message}")
    []
  end

  # +season+ is the year (a String, like CurrentSeason.year) whose leagues the start-date orderings list first.
  def initialize(listings, season:)
    @listings = listings
    @season = season
  end

  # The listed leagues in the given order (one of ORDERS); the default is by name.
  def leagues(order = :default)
    sorted(@listings, order)
  end

  private

  # Names are compared as plain strings, as legacy did: case-sensitive, so "BIG BOYS LEAGUE" sorts before
  # "Bottom Feeders".
  def sorted(leagues, order)
    case order
    when :default, :league_name then leagues.sort_by { |league| league.name }
    when :league_id then leagues.sort_by { |league| league.league_id }
    when :league_format then leagues.sort_by { |league| [ league.league_format, league.name ] }
    when :start_date then this_season_first(leagues)
    else raise ArgumentError, "unknown league order: #{order.inspect}"
    end
  end

  # The current season's leagues by start date (then name), followed by earlier seasons' the same way.
  def this_season_first(leagues)
    this_season, other = leagues.partition { |league| league.starts_in?(@season) }
    by_start_date = ->(league) { [ league.start_date, league.name ] }
    this_season.sort_by(&by_start_date) + other.sort_by(&by_start_date)
  end
end
