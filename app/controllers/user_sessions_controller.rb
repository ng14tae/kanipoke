class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new; end

  def create
    puts "受信パラメーター: #{params}"  # デバッグ用

    user = User.find_by(
      first_name: params[:first_name],
      last_name: params[:last_name]
    )

    if user && user.valid_password?(params[:password])
      auto_login(user)
      redirect_to root_path
    else
      flash[:alert] = "ログインに失敗しました"
      render :new
    end
  end

  def destroy
    logout
    redirect_to root_path, status: :see_other
  end
end
