module ApplicationHelper
  # <title> tag content: "Page Name | Pro Tour Fantasy Golf 2026", or the home page's own title when a page
  # doesn't set one. Replaces legacy's title=/full_title= controller-instance-variable hack, which only existed
  # to work around a Rails 2.3 partial-rendering-order quirk -- views just call content_for(:title, "...").
  def page_title_tag
    page_title = content_for(:title)
    if page_title.present?
      # safe_join, not string interpolation: content_for hands back an already-escaped SafeBuffer, which
      # interpolation would turn into a plain String and the layout's <%= %> would then escape a second time
      # (a visible "Commissioner&#39;s Corner" in the browser tab).
      safe_join([ page_title, "#{SITE_TITLE} #{CurrentSeason.year}" ], " | ")
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

  # A mailto: link whose address isn't in the page as plain text, to keep it away from simple scrapers. Rails 2's
  # mail_to(..., encode: "hex") did this and was dropped in Rails 4, so this reproduces its output: letters and
  # digits become %xx escapes, which every browser decodes when the link is clicked. The link text is whatever
  # the caller passes (never the address itself).
  def obfuscated_mail_to(address, text, subject: nil, **html_options)
    href = "mailto:" + address.gsub(/[[:alnum:]]/) { |char| format("%%%02x", char.ord) }
    href += "?subject=#{ERB::Util.url_encode(subject)}" if subject
    link_to text, href, html_options
  end
end
