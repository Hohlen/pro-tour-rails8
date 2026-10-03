require "test_helper"

class ErrorsTest < ActionDispatch::IntegrationTest
  # Test env shows Rails' own debug exception page (consider_all_requests_local), which would bypass
  # config.exceptions_app -- the thing under test -- so this turns detailed exceptions off, as production has them.
  setup do
    @original = Rails.application.env_config["action_dispatch.show_detailed_exceptions"]
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false
  end

  teardown do
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = @original
  end

  test "an unknown path renders the not-found page inside the site layout, with a 404" do
    get "/no/such/page"

    assert_response :not_found
    assert_select "title", /\APage Not Found \| Pro Tour Fantasy Golf \d{4}\z/
    assert_select "h2#pageTitle", "Error - Page Not Found"
    assert_select "nav.navbar-custom"
    assert_select "p a[href='#{root_path}']", "here"
  end

  test "an unknown path under a real section 404s too, and highlights no nav link" do
    get "/rules/nonexistent"

    assert_response :not_found
    assert_select "nav a.nav-link.active", count: 0
  end

  test "a POST to an unknown path 404s without tripping CSRF protection" do
    post "/nowhere"

    assert_response :not_found
    assert_select "h2#pageTitle", "Error - Page Not Found"
  end
end
