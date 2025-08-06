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
    @expert_only = false

    @last_week_champion = User.last_week_champion(expert_only: false)

      # 統計情報
    @total_users = User.count
    @active_users_this_week = @users.count
    @average_battles_this_week = @users.empty? ? 0 : (@users.sum(&:weekly_total_games) / @users.count.to_f).round(1)
  end

  def experienced_ranking
  @users = build_experienced_ranking_users
  @ranking_type = 'エキスパートランキング（戦績100回以上）'
  render :ranking # rankingビューを再利用
  end

  def expert?
    total_battles_count >= 100
  end

  # 期間指定でのエキスパート判定も追加
  def expert_since?(start_date)
    total_battles_count_since(start_date) >= 100
  end

  def expert_weekly_ranking
    today = Date.current
    monday = today.beginning_of_week(:monday)
    @start_date = monday.beginning_of_day
    @end_date = (monday + 6.days).end_of_day
    @update_time = Time.current


    # エキスパート限定の週間ランキングを取得
    @users = build_ranking_users(@start_date, 10, expert_only: true)
    @ranking_type = 'エキスパート週間ランキング'
    @period_description = "第#{today.cweek}週（#{@start_date.strftime('%m/%d')}〜#{@end_date.strftime('%m/%d')}）"
    @expert_only = true  # ビューで使用

    @last_week_champion = User.last_week_champion(expert_only: true)

    if @last_week_champion
      # 先週の期間を計算
      last_week_start = @start_date - 7.days
      last_week_end = @end_date - 7.days

      # 先週の統計を計算
      last_week_wins = @last_week_champion.wins_count_since(last_week_start)
      last_week_losses = @last_week_champion.losses_count_since(last_week_start)
      last_week_total = last_week_wins + last_week_losses
      last_week_rate = last_week_total > 0 ? (last_week_wins.to_f / last_week_total * 100) : 0

      # メソッドを動的に追加
      @last_week_champion.define_singleton_method(:weekly_wins) { last_week_wins }
      @last_week_champion.define_singleton_method(:weekly_losses) { last_week_losses }
      @last_week_champion.define_singleton_method(:weekly_total_games) { last_week_total }
      @last_week_champion.define_singleton_method(:weekly_win_rate) { last_week_rate }
    end

    @total_experts = User.select { |user| user.expert? }.count
    @active_experts_this_week = @users.count
    @average_battles_this_week = @users.empty? ? 0 : (@users.sum(&:weekly_total_games) / @users.count.to_f).round(1)

    render :weekly_ranking  # 既存のビューを再利用
  end

  private

  def build_ranking_users(start_date = nil, limit = nil, expert_only: false)
    # 関連データを一緒に読み込み
    users = User.includes(:battles, :battles_as_opponent, :won_battles)

    # バトル経験のあるユーザーのみ抽出
    users_with_battles = if start_date
      users.select { |user| user.has_battles_since?(start_date) }
    else
      users.select { |user| user.has_battles? }
    end

    if expert_only
      users_with_battles = users_with_battles.select { |user| user.expert? }
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


