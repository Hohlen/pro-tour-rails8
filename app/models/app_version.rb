# What's deployed, for the footer tooltip and the Version page. Reads the REVISION and REVISION_TIME files that
# Capistrano writes into each release directory (legacy's config/initializers/app_version.rb did the same, at
# boot, into constants). Everything falls back to "Unknown" when the files aren't there, which is the normal
# state in development and test. Phase 5 may swap the source if deployment moves to Kamal.
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

  # When that revision was committed (epoch seconds in the file), or "Unknown".
  def revision_time
    @revision_time_file.readable? ? Time.zone.at(@revision_time_file.read.strip.to_i) : UNKNOWN
  end

  # When it was deployed: the revision file's mtime, or when this process booted if there's no file.
  def deployed_at
    @revision_file.readable? ? @revision_file.mtime : BOOTED_AT
  end
end
