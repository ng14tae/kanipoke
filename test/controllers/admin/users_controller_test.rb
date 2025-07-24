require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_users_url  # 複数形
    assert_response :success
  end

  test "should get show" do
    user = users(:one)
    get admin_user_url(user)  # 単数形
    assert_response :success
  end
end
