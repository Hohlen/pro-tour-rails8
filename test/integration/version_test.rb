require "test_helper"

class VersionTest < ActionDispatch::IntegrationTest
  test "shows the Ruby and Rails versions and, with no REVISION files, Unknown for the deployed revision" do
    get version_path

    assert_response :success
    assert_select "title", /\AVersion Info \| Pro Tour Fantasy Golf \d{4}\z/
    assert_select "li", text: "Ruby Version: #{RUBY_VERSION}"
    assert_select "li", text: "Rails Version: #{Rails.version}"
    assert_select "li", text: "App Version: Unknown"
    assert_select "li", text: "Code Revision: Unknown"
    assert_select "li", text: /\ADeployed At: /
  end

  test "the Rails properties link is development-only" do
    get version_path

    assert_select "a[href='/rails/info/properties']", count: 0
  end

  test "the footer tooltip carries the revision too" do
    get version_path

    assert_select "#copyright[title^='Revision Unknown']"
  end
end
