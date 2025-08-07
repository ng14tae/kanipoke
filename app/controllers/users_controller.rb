class UsersController < ApplicationController
  before_action :require_login, except: [:new, :create]
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @my_win_count = current_user.won_battles.count
    @my_lose_count = current_user.lost_battles.count
    @my_total_battles = @my_win_count + @my_lose_count

    case params[:sort]
    when 'experienced_ranking'
      @users = User.experienced
                  .where.not(id: current_user.id)
                  .order('win_rate DESC, total_battles DESC')
                  .page(params[:page])
                  .per(12)

      @sort_type = 'エキスパートランキング（戦績100回以上）'
      @total_experienced_users = @users.total_count

    else
      @users = User.where.not(id: current_user.id)
                  .order(created_at: :asc)
                  .page(params[:page])
                  .per(12)
      @sort_type = '登録順'
    end
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
    today = Date.current
    monday_this_week = today.beginning_of_week(:monday)

    # 今週の期間
    @start_date = monday_this_week.beginning_of_day
    @end_date = (monday_this_week + 6.days).end_of_day

    # 先週の期間を明示的に計算
    last_week_start = @start_date - 7.days
    last_week_end = @end_date - 7.days

    @users = build_ranking_users(@start_date, 10)
    @ranking_type = '週間ランキング'

    week_number = today.cweek
    @period_description = "第#{week_number}週（#{@start_date.strftime('%m/%d')}〜#{@end_date.strftime('%m/%d')}）"
    @update_time = Time.current
    @expert_only = false

    #  修正：先週の期間を使って正しく王者を取得
    @last_week_champion = get_last_week_champion(last_week_start, last_week_end, expert_only: false)

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

    # 先週の期間を明示的に計算
    last_week_start = @start_date - 7.days
    last_week_end = @end_date - 7.days

    all_weekly_ranking = User.weekly_ranking(@start_date)

    @users = all_weekly_ranking.select do |stats|
      stats[:total_games] >= 100
    end.take(10)

    @ranking_type = 'エキスパート週間ランキング'
    @period_description = "第#{today.cweek}週（#{@start_date.strftime('%m/%d')}〜#{@end_date.strftime('%m/%d')}）"
    @expert_only = true

    # ✅ 統一：同じメソッドを使用
    @last_week_champion = get_last_week_champion(last_week_start, last_week_end, expert_only: true)

    render :weekly_ranking
  end

  private

  def build_ranking_users(start_date = nil, limit = nil, expert_only: false)
    # データ規模に合わせた適切なlimit設定
    limit ||= determine_appropriate_limit(start_date, expert_only)

    query = build_ranking_query(start_date, expert_only)

    users_with_stats = query.limit(limit).map do |user|
      add_weekly_stats_methods(user)
      user
    end

    users_with_stats
  end

  def build_experienced_ranking_users
    User.joins(:battles)
        .group('users.id')
        .having('COUNT(battles.id) >= 100')
        .select('users.*, 
                COUNT(battles.id) as total_battles,
                SUM(CASE WHEN battles.winner_id = users.id THEN 1 ELSE 0 END) as wins_count,
                ROUND((SUM(CASE WHEN battles.winner_id = users.id THEN 1 ELSE 0 END) * 100.0 / COUNT(battles.id)), 1) as win_rate')
        .order('win_rate DESC, total_battles DESC')
        .limit(20)
        .map { |user| add_total_stats_methods(user) }
  end

  def determine_appropriate_limit(start_date, expert_only)
    if expert_only
      20    # エキスパートユーザー（100戦以上）は少数想定
    elsif start_date
      30    # 週間アクティブユーザー
    else
      50    # 全ユーザー（40人なので全員でもOK）
    end
  end

  def build_ranking_query(start_date, expert_only)
    # ユーザーが参加した全試合を取得
    query = User.joins("LEFT JOIN battles ON (battles.user_id = users.id OR battles.opponent_id = users.id)")
                .where("battles.id IS NOT NULL")

    # 期間フィルター
    if start_date
      end_date = start_date.end_of_week(:monday).end_of_day
      query = query.where(battles: { created_at: start_date..end_date })
    end

    # グループ化とフィルター
    query = query.group('users.id')

    if expert_only
      query = query.having('COUNT(battles.id) >= 100')
    else
      query = query.having('COUNT(battles.id) > 0')
    end

    # 統計情報を選択
    query.select(
      'users.*, ' \
      'COUNT(battles.id) as weekly_total_games, ' \
      'SUM(CASE WHEN battles.winner_id = users.id THEN 1 ELSE 0 END) as weekly_wins, ' \
      '(COUNT(battles.id) - SUM(CASE WHEN battles.winner_id = users.id THEN 1 ELSE 0 END)) as weekly_losses, ' \
      'ROUND((SUM(CASE WHEN battles.winner_id = users.id THEN 1 ELSE 0 END) * 100.0 / COUNT(battles.id)), 1) as weekly_win_rate'
    ).order('weekly_win_rate DESC, weekly_total_games DESC')
  end

  def add_weekly_stats_methods(user)
    total = user.read_attribute('weekly_total_games') || 0
    wins = user.read_attribute('weekly_wins') || 0
    losses = user.read_attribute('weekly_losses') || 0
    win_rate = user.read_attribute('weekly_win_rate') || 0.0

    user.define_singleton_method(:weekly_total_games) { total }
    user.define_singleton_method(:weekly_wins) { wins }
    user.define_singleton_method(:weekly_losses) { losses }
    user.define_singleton_method(:weekly_win_rate) { win_rate }
    user
  end

  def add_total_stats_methods(user)
    total = user.read_attribute('total_battles') || 0
    wins = user.read_attribute('wins_count') || 0
    win_rate = user.read_attribute('win_rate') || 0.0

    user.define_singleton_method(:total_battles_count) { total }
    user.define_singleton_method(:wins_count) { wins }
    user.define_singleton_method(:win_rate) { win_rate }
    user
  end

  # 先週の王者を取得する統一メソッド
  def get_last_week_champion(start_date, end_date, expert_only: false)
    last_week_ranking = User.weekly_ranking(start_date)
    return nil if last_week_ranking.blank?

    if expert_only
      last_week_ranking = last_week_ranking.select { |stats| stats[:total_games] >= 100 }
      return nil if last_week_ranking.blank?
    end

    champion_stats = last_week_ranking.first
    return nil unless champion_stats

    # ✅ 安全なユーザー取得
    user_id = champion_stats[:user_id] || champion_stats['user_id']
    return nil if user_id.blank?

    begin
      champion = User.find(user_id)
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn "Champion user not found: #{user_id}"
      return nil
    end

    # 統計メソッドの追加
    champion.define_singleton_method(:weekly_wins) { champion_stats[:wins] || 0 }
    champion.define_singleton_method(:weekly_losses) { champion_stats[:losses] || 0 }
    champion.define_singleton_method(:weekly_total_games) { champion_stats[:total_games] || 0 }
    champion.define_singleton_method(:weekly_win_rate) { champion_stats[:win_rate] || 0.0 }

    champion
  rescue => e
    Rails.logger.error "Error in get_last_week_champion: #{e.message}"
    nil
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
