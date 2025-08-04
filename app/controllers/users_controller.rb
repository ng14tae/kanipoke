class UsersController < ApplicationController
  before_action :require_login, except: [:new, :create]
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @my_win_count = current_user.won_battles.count
    @my_lose_count = current_user.lost_battles.count
    @my_total_battles = @my_win_count + @my_lose_count
    @users = User.where.not(id: current_user.id)
              .includes(:won_battles, :lost_battles)

    case params[:sort]
    when 'win_rate'
      # 勝率順（勝率の高い順）
      # バトル経験のあるユーザーのみを対象にして勝率でソート
      users_with_battles = @users.select { |user| user.total_battles_count > 0 }
      users_without_battles = @users.select { |user| user.total_battles_count == 0 }

      # 勝率順でソート（勝率が同じ場合は総試合数の多い順）
      sorted_with_battles = users_with_battles.sort_by do |user|
        [-user.win_rate, -user.total_battles_count]
      end

      # バトル経験ありのユーザー → バトル経験なしのユーザーの順で配列を結合
      @users = sorted_with_battles + users_without_battles.sort_by(&:created_at)
      @sort_type = 'ランキング順（勝率の高い順）'
      when 'experienced_ranking'
      # 戦績100回以上のユーザーのみでランキング
      experienced_users = @users.select { |user| user.total_battles_count >= 100 }

      # 戦績100回以上のユーザーを勝率でソート
      @users = experienced_users.sort_by do |user|
        [-user.win_rate, -user.total_battles_count]
      end

      @sort_type = 'エキスパートランキング（戦績100回以上）'
      @total_experienced_users = experienced_users.count

    else
      # デフォルトは登録順（作成日の昇順）
      @users = @users.order(created_at: :asc)
      @sort_type = '登録順'
    end

    # ページネーション
    @users = Kaminari.paginate_array(@users)
                     .page(params[:page])
                     .per(12)            # 12人ずつ表示（3×4のグリッドレイアウトに最適）
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

  def destroy
    @user.destroy
    redirect_to users_path, notice: 'ユーザーを削除しました'
  end

  def ranking
    @users = build_ranking_users
    @ranking_type = '総合ランキング'
  end

  def weekly_ranking
    # 現在の日付を基準に今週の範囲を計算
    today = Date.current

    # 今週の月曜日を取得
    monday_this_week = today.beginning_of_week(:monday)

    # 月曜日から日曜日まで（7日間完全）
    @start_date = monday_this_week.beginning_of_day
    @end_date = (monday_this_week + 6.days).end_of_day  # 月曜 + 6日 = 日曜

    # ランキングデータの取得
    @users = build_ranking_users(@start_date, 10)
    @ranking_type = '週間ランキング'

    # 週の情報を計算
    week_number = today.cweek
    @period_description = "第#{week_number}週（#{@start_date.strftime('%m/%d')}〜#{@end_date.strftime('%m/%d')}）"
    @update_time = Time.current
  end

  def experienced_ranking
  @users = build_experienced_ranking_users
  @ranking_type = 'エキスパートランキング（戦績100回以上）'
  render :ranking # rankingビューを再利用
  end

  private

  def build_ranking_users(start_date = nil, limit = nil)
    # 関連データを一緒に読み込み
    users = User.includes(:battles, :battles_as_opponent, :won_battles)

    # バトル経験のあるユーザーのみ抽出
    users_with_battles = if start_date
      users.select { |user| user.has_battles_since?(start_date) }
    else
      users.select { |user| user.has_battles? }
    end

    # 各ユーザーに週間統計データを追加
    users_with_stats = users_with_battles.map do |user|
      # 期間に応じて統計を計算
      if start_date
        total_games = user.total_battles_count_since(start_date)
        wins = user.wins_count_since(start_date)
        losses = user.losses_count_since(start_date)
        win_rate = user.win_rate_since(start_date)
      else
        total_games = user.total_battles_count
        wins = user.wins_count
        losses = user.losses_count
        win_rate = user.win_rate
      end

      # ユーザーオブジェクトに統計メソッドを動的追加
      user.define_singleton_method(:weekly_total_games) { total_games }
      user.define_singleton_method(:weekly_wins) { wins }
      user.define_singleton_method(:weekly_losses) { losses }
      user.define_singleton_method(:weekly_win_rate) { win_rate }

      user
    end

    # 勝率でソート（勝率が同じ場合は総試合数でソート）
    sorted_users = users_with_stats.sort_by do |user|
      [-user.weekly_win_rate, -user.weekly_total_games]
    end

    # limit指定がある場合は上位のみを返す
    limit ? sorted_users.first(limit) : sorted_users
  end

  def build_experienced_ranking_users
    users = User.includes(:battles, :battles_as_opponent, :won_battles)

    # 戦績100回以上のユーザーのみを抽出
    experienced_users = users.select { |user| user.total_battles_count >= 100 }

    # 勝率でソート（勝率が同じ場合は総試合数でソート）
    experienced_users.sort_by do |user|
      [-user.win_rate, -user.total_battles_count]
    end
  end


  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :password, :password_confirmation)
  end

  def calculate_win_rate(user)
    user.win_rate
  end
end
