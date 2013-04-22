require 'test_helper'

class RestControllerTest < ActionController::TestCase
  test "should get rest" do
    get :rest
    assert_response :success
  end

end
