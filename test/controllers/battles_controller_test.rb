require "test_helper"

class BattlesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)  # fixtureのユーザーを使用
    # ログイン処理
    post login_url, params: { password: "password" }
  end

  test "should get index" do
    get battles_url  # 複数形
    assert_response :success
  end

  test "should get new" do
    get new_battle_url  # 単数形
    assert_response :success
  end

  test "should get show" do
    battle = battles(:one)  # fixture使用
    get battle_url(battle)  # 単数形
    assert_response :success
  end

  test "should get create" do
    # createアクションのテストにはパラメータが必要
    opponent = users(:two)  # 対戦相手
    post battles_url, params: {
      battle: {
        opponent_id: opponent.id
      }
    }
    # createは通常リダイレクトするので
    assert_response :redirect
  end
end
