require "test_helper"

class Admin::BattlesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_battles_url
    assert_response :success
  end

  test "should get show" do
    get admin_battle_url
    assert_response :success
  end
end
