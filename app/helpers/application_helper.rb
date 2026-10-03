module ApplicationHelper
  # <title> tag content: "Page Name | Pro Tour Fantasy Golf 2026", or the home page's own title when a page
  # doesn't set one. Replaces legacy's title=/full_title= controller-instance-variable hack, which only existed
  # to work around a Rails 2.3 partial-rendering-order quirk -- views just call content_for(:title, "...").
  def page_title_tag
    page_title = content_for(:title)
    if page_title.present?
      "#{page_title} | #{SITE_TITLE} #{CurrentSeason.year}"
    else
      "#{SITE_TITLE} #{CurrentSeason.year} | Online Hosting For Fantasy Golf Leagues"
    end
  end

  # Bootstrap 5's active nav-link class. Matches on path prefix, not exact path, like legacy's module_item (which
  # matched on controller): /leagues/by_league_name must keep "Leagues" lit, /contact_us/thank_you "Contact Us".
  # The home page is the one exact match, since every path starts with "/".
  def nav_link_class(path)
    active = if path == root_path
      request.path == root_path
    else
      request.path == path || request.path.start_with?("#{path}/")
    end
    active ? "nav-link active" : "nav-link"
  end
end
