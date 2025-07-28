class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new; end

  def create
    Rails.logger.info "受信パラメーター: #{params.inspect}"

    # Sorceryでのログイン処理
    user = User.find_by(first_name: params[:first_name], last_name: params[:last_name])

    if user && user.valid_password?(params[:password])
      auto_login(user)
      redirect_to root_path, notice: "ログインしました"
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
