require "test_helper"

# Still-unported pages (Phase 2: Leagues, Phase 3: Contact Us). Delete this file along with
# PlaceholdersController once neither is left.
class PlaceholdersTest < ActionDispatch::IntegrationTest
  {
    "/leagues" => "Leagues",
    "/contact_us" => "Contact Us"
  }.each do |path, title|
    test "#{path} renders a placeholder titled #{title} and lights its own nav link" do
      get path

      assert_response :success
      assert_select "title", /\A#{Regexp.escape(title)} \| Pro Tour Fantasy Golf \d{4}\z/
      assert_select "h2#pageTitle", title
      assert_select "nav a.nav-link.active[href='#{path}']", count: 1
      assert_select ".ptfgTagline", "Where a bad round never spoils the fun!"
    end
  end
end
