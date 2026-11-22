class SessionsController < ApplicationController
  def new
  end

  def create
    credentials = params.require(:session).permit(:email, :password, :remember_me)
    user = User.find_by(email: credentials[:email].to_s.downcase)
    if user&.authenticate(credentials[:password].to_s)
      reset_session
      credentials[:remember_me] == "1" ? remember(user) : forget(user)
      log_in user
      redirect_to user
    else
      flash.now[:danger] = "Invalid email/password combination"
      render "new", status: :unprocessable_entity
    end
  end

  def destroy
    log_out
    redirect_to root_url, status: :see_other
  end
end
