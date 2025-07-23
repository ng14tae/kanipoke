require "test_helper"

class Admin::CharactersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_characters_index_url
    assert_response :success
  end

  test "should get show" do
    get admin_characters_show_url
    assert_response :success
  end

  test "should get new" do
    get admin_characters_new_url
    assert_response :success
  end

  test "should get create" do
    get admin_characters_create_url
    assert_response :success
  end

  test "should get edit" do
    get admin_characters_edit_url
    assert_response :success
  end

  test "should get update" do
    get admin_characters_update_url
    assert_response :success
  end

  test "should get destroy" do
    get admin_characters_destroy_url
    assert_response :success
  end
end
