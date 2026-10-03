# The season the site is currently advertising. Rolls over to next year on Nov 1 so the upcoming season is
# what visitors see through the winter. Ported from legacy's CURRENT_SEASON constant, but computed on every
# call: legacy evaluated it once at boot, so a long-running server kept showing last year's season after
# the rollover until its next restart.
module CurrentSeason
  def self.year
    (Time.current + 2.months).year.to_s
  end
end
