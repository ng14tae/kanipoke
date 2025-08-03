class UsersController < ApplicationController
  before_action :require_login, except: [:new, :create]
  before_action :set_user, only: [:show, :edit, :update]

  def index
    @my_win_count = current_user.won_battles.count
    @my_lose_count = current_user.lost_battles.count
    @my_total_battles = @my_win_count + @my_lose_count
    @users = User.where.not(id: current_user.id)
              .includes(:won_battles, :lost_battles)

    # ページネーション対応
    @users = User.where.not(id: current_user.id)
              .includes(:won_battles, :lost_battles)
              .order(created_at: :desc)  # 並び順を明確に指定
              .page(params[:page])       # ページネーション追加
              .per(12)                   # 12人ずつ表示（3×4のグリッドレイアウトに最適）
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to root_path
    else
      render :new
    end
  end

  def show
  @battles = @user.battles.includes(:user, :opponent).order(created_at: :desc).limit(10)
  @win_rate = calculate_win_rate(@user)
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: "プロフィールを更新しました！"
    else
      render :edit
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :password, :password_confirmation)
  end

  def calculate_win_rate(user)
    total_battles = user.battles.count
    return 0 if total_battles == 0

    won_battles = Battle.where(winner_id: user.id).count
    (won_battles.to_f / total_battles * 100).round(1)
  end
end
