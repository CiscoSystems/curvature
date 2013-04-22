require 'test_helper'

class VisualisationControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

end
