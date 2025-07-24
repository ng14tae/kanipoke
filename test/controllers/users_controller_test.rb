require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
    test "should get index when logged in" do
    # ユーザーを作成
    user = users(:one)  # fixtureを使用

    # ログイン処理
    post login_url, params: { password: "password" }

    # テスト実行
    get users_url
    assert_response :success
  end
end
