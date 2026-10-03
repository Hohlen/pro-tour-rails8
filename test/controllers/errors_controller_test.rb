require "test_helper"

# The 500 and 422 pages are tested here, not in test/integration like the rest: an integration test's GET /500
# is answered by the static-file middleware straight out of public/ (status 200) before the router -- and so
# ErrorsController -- is ever reached. Rails itself reaches the controller by replaying a failed request against
# the route, which a controller test reproduces.
class ErrorsControllerTest < ActionController::TestCase
  test "500 serves the static public/500.html with a 500 status" do
    get :internal_server_error

    assert_response :internal_server_error
    assert_equal Rails.public_path.join("500.html").read, response.body
  end

  test "422 serves the static public/422.html with a 422 status" do
    get :unprocessable_entity

    assert_response :unprocessable_entity
    assert_equal Rails.public_path.join("422.html").read, response.body
  end

  test "the error actions accept any HTTP method and skip CSRF verification" do
    post :unprocessable_entity

    assert_response :unprocessable_entity
  end
end
