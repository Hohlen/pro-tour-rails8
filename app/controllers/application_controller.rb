class ApplicationController < ActionController::Base
  # Deliberately no allow_browser (the Rails 8 default of `versions: :modern`): league commissioners and
  # participants include people on older iPads/iPhones that would otherwise get a 406 page instead of the site.
  # Same choice as storks-now-rails8.

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
