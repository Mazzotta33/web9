require "test_helper"

class SessionsHelperTest < ActionView::TestCase
  def setup
    @user = users(:michael)
    remember(@user)
  end

  test "remember cookies restore a missing session" do
    assert_nil session[:user_id]
    assert_equal @user, current_user
    assert_equal @user.id, session[:user_id]
    assert_equal @user.reload.remember_digest, session[:session_token]
    assert logged_in?
  end

  test "a mismatched digest cannot restore a session" do
    @user.update_attribute(:remember_digest, User.digest(User.new_token))
    assert_nil current_user
    assert_not logged_in?
  end

  test "a revoked digest cannot restore a session" do
    @user.forget
    assert_nil current_user
  end

  test "a missing token cannot restore a session" do
    cookies.delete(:remember_token)
    assert_nil current_user
  end

  test "a deleted user cannot restore a session" do
    @user.destroy!
    assert_nil current_user
  end

  test "tampered user id cookie cannot restore a session" do
    cookies[:user_id] = "tampered"
    assert_nil current_user
  end

  test "session token mismatch rejects a copied session" do
    log_in_as(@user)
    @user.remember
    assert_nil current_user
    assert_not logged_in?
  end

  test "forgetting the user invalidates an existing session" do
    log_in_as(@user)
    @user.forget
    assert_nil current_user
  end
end
