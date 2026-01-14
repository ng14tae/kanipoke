class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new; end

  def create
    user = User.find_by(first_name: params[:first_name], last_name: params[:last_name])

    if user&.valid_password?(params[:password])
      auto_login(user)
      redirect_to root_path, notice: "ログインしました"
    else
      flash.now[:alert] = "ログインに失敗しました"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    redirect_to root_path, notice: "ログアウトしました", status: :see_other
  end
end
