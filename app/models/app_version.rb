# What's deployed, for the footer tooltip and the Version page. Reads the REVISION and REVISION_TIME files that
# Capistrano writes into each release directory (legacy's config/initializers/app_version.rb did the same, at
# boot, into constants). Everything falls back to "Unknown" when the files aren't there, which is the normal
# state in development and test.
class AppVersion
  UNKNOWN = "Unknown".freeze
  BOOTED_AT = Time.current

  def self.current
    @current ||= new(Rails.root)
  end

  def initialize(root)
    @revision_file = Pathname(root).join("REVISION")
    @revision_time_file = Pathname(root).join("REVISION_TIME")
  end

  # The deployed git revision.
  def revision
    @revision_file.readable? ? @revision_file.read.strip : UNKNOWN
  end

  # When that revision was committed (epoch seconds in the file), or "Unknown" -- also when the file is empty or
  # doesn't hold a number, which would otherwise show as 1970.
  def revision_time
    epoch = @revision_time_file.readable? ? @revision_time_file.read.strip.to_i : 0
    epoch.positive? ? Time.zone.at(epoch) : UNKNOWN
  end

  # When it was deployed: the revision file's mtime, or when this process booted if there's no file. In the
  # app's time zone, like every other time on the site, not whatever zone the server happens to be set to.
  def deployed_at
    @revision_file.readable? ? Time.zone.at(@revision_file.mtime) : BOOTED_AT
  end
end
