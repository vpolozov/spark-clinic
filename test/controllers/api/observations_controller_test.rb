require "test_helper"

class Api::ObservationsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get api_observations_create_url
    assert_response :success
  end
end
