require "test_helper"

class UsersRememberTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
  end

  test "login form offers an unchecked remember option" do
    get login_path
    assert_select "input[type=checkbox][name='session[remember_me]'][value='1']"
    assert_select "input#session_remember_me[checked]", count: 0
  end

  test "remembered login stores a token matching the database digest" do
    log_in_as(@user)
    assert_redirected_to @user
    assert is_logged_in?
    assert_not cookies[:remember_token].blank?
    assert_not cookies[:user_id].blank?
    assert @user.reload.authenticated?(cookies[:remember_token])
    assert_equal @user.remember_digest, session[:session_token]
    assert_not_equal @user.id.to_s, cookies[:user_id]
  end

  test "unchecked option deletes previously issued remember cookies" do
    log_in_as(@user)
    previous_token = cookies[:remember_token]
    log_in_as(@user, remember_me: "0")
    assert is_logged_in?
    assert cookies[:remember_token].blank?
    assert cookies[:user_id].blank?
    assert_not @user.reload.authenticated?(previous_token)
    follow_redirect!
    assert_select "a[href=?]", logout_path
  end

  test "a fresh browser session restores login from persistent cookies" do
    log_in_as(@user)
    browser = open_session
    browser.cookies[:user_id] = cookies[:user_id]
    browser.cookies[:remember_token] = cookies[:remember_token]
    browser.get root_path
    browser.assert_response :success
    browser.assert_select "a[href=?]", user_path(@user)
    browser.assert_select "a[href=?]", login_path, count: 0
    assert_equal @user.id, browser.session[:user_id]
  end

  test "copied remember cookies cannot restore login after logout" do
    log_in_as(@user)
    browser = open_session
    browser.cookies[:user_id] = cookies[:user_id]
    browser.cookies[:remember_token] = cookies[:remember_token]
    delete logout_path
    browser.get root_path
    browser.assert_response :success
    browser.assert_select "a[href=?]", login_path
    assert_nil browser.session[:user_id]
  end

  test "omitting remember option only creates a temporary session" do
    post login_path, params: { session: { email: @user.email, password: "password" } }
    assert is_logged_in?
    assert cookies[:remember_token].blank?
    assert cookies[:user_id].blank?
  end

  test "remembered logout revokes the token and can be repeated" do
    log_in_as(@user)
    token = cookies[:remember_token]
    delete logout_path
    assert_response :see_other
    assert_not is_logged_in?
    assert_nil @user.reload.remember_digest
    assert_not @user.authenticated?(token)
    assert cookies[:remember_token].blank?
    assert cookies[:user_id].blank?
    delete logout_path
    assert_response :see_other
    follow_redirect!
    assert_select "a[href=?]", login_path
  end

  test "revoking the digest makes an existing session anonymous" do
    log_in_as(@user)
    @user.reload.forget
    get root_path
    assert_select "a[href=?]", login_path
    assert_select "#account", count: 0
  end

  test "failed authentication cannot issue remember cookies" do
    log_in_as(@user, password: "wrong")
    assert_response :unprocessable_entity
    assert_not is_logged_in?
    assert cookies[:remember_token].blank?
    assert_nil @user.reload.remember_digest
  end
end
